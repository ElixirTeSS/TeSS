# frozen_string_literal: true

require 'icalendar'
require 'nokogiri'
require 'tzinfo'
require 'uri'
require 'openssl'
require 'net/http'
require 'socket'

module Ingestors
  class IndicoIngestor < Ingestor
    include Ingestors::Concerns::SitemapHelpers

    def self.config
      {
        key: 'indico',
        title: 'Indico / .ics file',
        category: :events
      }
    end

    def read(source_url)
      @verbose = false

      @summary = {
        started_at: Time.current,
        source_urls: 0,
        successful_calendars: 0,
        failed_calendars: 0,
        parsed_events: 0,
        imported_events: 0,
        failed_events: 0
      }

      sources = parse_sitemap(source_url)
      @summary[:source_urls] = sources.size

      Rails.logger.info(
        "[Indico] Starting ingestion of #{sources.size} sources"
      )

      sources.each do |url|
        process_url(url)
      end
    ensure
      print_summary_report if @summary
    end

    private

    def process_url(url)
      Rails.logger.info("[Indico] Processing source URL: #{url}")

      export_url = to_export(url)
      raise 'NOT an Indico link' if export_url.nil?

      content = fetch_calendar_content(export_url)

      @summary[:successful_calendars] += 1

      Rails.logger.info(
        "[Indico] Response size: #{content.bytesize} bytes"
      )

      Rails.logger.debug(
        "[Indico] response preview: #{content[0, 500].inspect}"
      )

      calendars = Icalendar::Calendar.parse(content)
      events = Array(calendars).flat_map(&:events)

      @summary[:parsed_events] += events.size

      Rails.logger.info(
        "[Indico] Parsed #{events.size} events from #{export_url}!"
      )

      if events.empty?
        Rails.logger.info(
          "[Indico] No events found in calendar feed: #{export_url}"
        )
        return
      end

      # Sort chronologically: newest event first.
      sorted_events = events.sort_by do |calevent|
        calevent.dtstart&.to_time || Time.at(0).utc
      end

      sorted_events.reverse!

      Rails.logger.info(
        '[Indico] Processing events ... [IN PROGRESS]'
      )

      sorted_events.each do |calevent|
        process_calevent(calevent)

        @summary[:imported_events] += 1
      rescue StandardError => e
        @summary[:failed_events] += 1

        Rails.logger.error(
          'Indico: failed to process event ' \
          "#{calevent.uid}: #{e.class} - #{e.message}"
        )

        @messages << 'Failed to process Indico event ' \
          "#{calevent.uid}: #{e.message}"
      end
    rescue StandardError => e
      @summary[:failed_calendars] += 1

      Rails.logger.error(
        "Indico ERROR for #{url}: #{e.class} - #{e.message}"
      )

      messages << "Process file URL [#{url}] failed with: #{e.message}"
    end

    def fetch_calendar_content(url)
      uri = URI.parse(url)
      raise ArgumentError, "Unsupported calendar URL: #{url}" unless uri.is_a?(URI::HTTP)

      # Preserve existing query parameters and ensure nc=yes.
      params = URI.decode_www_form(uri.query.to_s)
      params.reject! { |key, _value| key == 'nc' }
      params << %w[nc yes]

      uri.query = URI.encode_www_form(params)

      Rails.logger.info("[Indico] Opening calendar URI: #{uri}")

      Rails.logger.info(
        "[Indico] Ruby=#{RUBY_VERSION}, " \
        "OpenSSL=#{OpenSSL::OPENSSL_VERSION}, " \
        "SSL_CERT_FILE=#{ENV['SSL_CERT_FILE'].inspect}"
      )

      max_attempts = 3

      max_attempts.times do |attempt|
        Rails.logger.info(
          "[Indico] HTTP request attempt #{attempt + 1}/#{max_attempts}"
        )

        options = {
          read_timeout: 60,
          open_timeout: 30,
          'User-Agent' => 'egi-automation',
          'Accept' => 'text/calendar'
        }

        response = open_url(uri.to_s, raise: true, open_options: options)

        Rails.logger.info(
          "[Indico] HTTP status: #{response.status.inspect}"
        )

        Rails.logger.info(
          "[Indico] HTTP Content-Type: #{response.meta['content-type']}"
        )

        return response.read.force_encoding(Encoding::UTF_8)
      rescue Net::OpenTimeout,
             Net::ReadTimeout,
             Errno::ECONNRESET,
             Errno::ECONNREFUSED,
             SocketError => e

        Rails.logger.warn(
          "[Indico] Network error on attempt #{attempt + 1}: " \
          "#{e.class} - #{e.message}"
        )

        raise if attempt == max_attempts - 1

        delay = 2**attempt

        Rails.logger.info(
          "[Indico] Retrying in #{delay} seconds..."
        )

        sleep(delay)
      end
    end

    def to_export(url)
      uri = URI.parse(url)

      # Convert category page/feed URLs to Indico's HTTP API endpoint.
      match = uri.path.match(%r{/category/(\d+)(?:/events\.ics)?/?$})

      if match
        category_id = match[1]
        uri.path = "/export/categ/#{category_id}.ics"

        params = URI.decode_www_form(uri.query.to_s)

        params.reject! do |key, _value|
          %w[from to nc].include?(key)
        end

        params << %w[from 1900-01-01]
        params << %w[to 2100-12-31]
        params << %w[nc yes]

        uri.query = URI.encode_www_form(params)

        return uri.to_s
      end

      return url if uri.path.to_s.end_with?('.ics')
      return nil unless indico_page?(uri)

      ensure_events_ics_path(uri)
    end

    def indico_page?(uri)
      return false if uri.host.nil?

      uri.host.include?('indico')
    end

    def ensure_events_ics_path(uri)
      path = uri.path.to_s.chomp('/')

      path = "#{path}/events.ics" unless path.end_with?('/events.ics')

      uri.path = path
      uri.to_s
    end

    def process_calevent(calevent)
      Rails.logger.info(
        "Event=#{calevent.uid.inspect}, " \
        "Title=#{calevent.summary.to_s.inspect}, " \
        "Start=#{calevent.dtstart.inspect}"
      )

      event = Event.new

      assign_basic_info(event, calevent)
      assign_time_info(event, calevent)
      assign_location_info(event, calevent)

      add_event(event.attributes)
    end

    def assign_basic_info(event, calevent)
      event.url = calevent.url.to_s
      event.title = calevent.summary.to_s
      event.description = calevent.description.to_s
      event.keywords = Array(calevent.categories).flatten
      event.contact = Array(calevent.contact).join(', ')
    end

    def assign_time_info(event, calevent)
      event.start = calevent.dtstart&.to_time
      event.end = calevent.dtend&.to_time
      event.timezone = get_tzid(calevent.dtstart)
    end

    def assign_location_info(event, calevent)
      location = calevent.location
      return if location.blank?

      description = calevent.description.to_s.downcase

      online = description.include?('zoom')

      hybrid = description.include?('hybrid') &&
               !description.include?('not hybrid') &&
               !description.include?('not a hybrid')

      event.venue = location.to_s
      event.online = online || hybrid

      event.presence =
        if hybrid
          :hybrid
        elsif online
          :online
        else
          :onsite
        end
    end

    def get_tzid(dtstart)
      return nil unless dtstart.respond_to?(:ical_params)

      tzid = dtstart.ical_params['tzid']
      return nil if tzid.nil?

      tzid.is_a?(Array) ? tzid.first.to_s : tzid.to_s
    end

    # ----------------------------------------------------------
    # SUMMARY REPORT
    # ----------------------------------------------------------

    def print_summary_report
      summary = @summary
      finished_at = Time.current
      duration = (finished_at - summary[:started_at]).round(2)

      report = <<~REPORT

        ============================================================
                       INDICO INGESTION SUMMARY
        ============================================================

        Started at:              #{summary[:started_at]}
        Finished at:             #{finished_at}
        Duration:                #{duration} seconds

        SOURCE CALENDARS
        ------------------------------------------------------------
        Total source URLs:       #{summary[:source_urls]}
        Successful calendars:    #{summary[:successful_calendars]}
        Failed calendars:        #{summary[:failed_calendars]}

        EVENTS
        ------------------------------------------------------------
        Events parsed:           #{summary[:parsed_events]}
        Events imported:         #{summary[:imported_events]}
        Events failed:           #{summary[:failed_events]}

        ============================================================

      REPORT

      Rails.logger.info(report)
    end
  end
end
