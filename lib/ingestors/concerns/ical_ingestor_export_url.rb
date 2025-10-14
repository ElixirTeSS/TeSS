# frozen_string_literal: true

module Ingestors
  module Concerns
    # Gets the proper URL to export an ics or ical
    module IcalIngestorExportUrl
      private

      # 1. If the host includes 'indico', ensures the path ends with '/events.ics'.
      # 2. If the path already ends with '/events.ics', return as-is.
      # 3. Otherwise, append '?ical=true' query param if not already present.
      #
      # This method never mutates the original URL string.
      # Returns the updated URL string or nil if input is blank.
      def to_export(url)
        return nil if url.blank?

        uri = URI.parse(url)
        path = uri.path.to_s

        if uri.host&.include?('indico')
          ensure_events_ics_path(uri)
        elsif path.match?(%r{/(event|events)\.ics\z})
          uri.to_s
        else
          ensure_ical_query(uri)
        end
      end

      # Ensures the Indico URL ends with '/events.ics'
      def ensure_events_ics_path(uri)
        if uri.path&.include?('event')
          uri.path = File.join(uri.path, 'event.ics') unless uri.path.end_with?('/event.ics')
        elsif uri.path&.include?('category')
          uri.path = File.join(uri.path, 'events.ics') unless uri.path.end_with?('/events.ics')
        end
        uri.to_s
      end

      # Ensures the URL has '?ical=true' in its query params
      def ensure_ical_query(uri)
        query = URI.decode_www_form(uri.query.to_s).to_h
        query['ical'] = 'true' unless query['ical'] == 'true'
        uri.query = URI.encode_www_form(query)
        uri.to_s
      end
    end
  end
end
