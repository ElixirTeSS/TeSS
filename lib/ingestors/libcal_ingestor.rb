require 'open-uri'
require 'csv'

module Ingestors
  class LibcalIngestor < Ingestor
    def self.config
      {
        key: 'libcal_event',
        title: 'Libcal Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_libcal(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_libcal(url)
      # execute REST request
      results = get_JSON_response url
      data = results.to_h['results']

      # extract materials from results
      unless data.nil? or data.size < 1
        data.each do |item|
          # create new event
          event = Event.new

          # extract event details from
          attr = item
          event.title = attr.fetch('title', '')
          event.url = attr.fetch('url', '')&.strip
          event.organizer = attr.fetch('org', '')
          event.description = convert_description attr.fetch('description', '')
          event.start = attr.fetch('startdt', '')
          event.end = attr.fetch('enddt', '')
          event.set_default_times
          event.venue = attr.fetch('location', '')
          if url.starts_with? 'https://vu-nl.libcal.com'
            event.city = 'Amsterdam'
            event.country = 'The Netherlands'
            event.source = 'VU Amsterdam'
          elsif url.starts_with? 'https://eur-nl.libcal.com'
            event.city = 'Rotterdam'
            event.country = 'The Netherlands'
            event.source = 'EUR'
          end
          event.online = attr.fetch('online_event', '')
          event.contact = attr.fetch('orgurl', '')
          event.timezone = 'Amsterdam'

          # array fields
          event.keywords = []
          attr['categories_arr']&.each { |category| event.keywords << category['name'] }

          event.event_types = []
          attr['event_types']&.each do |key|
            value = convert_event_types(key)
            event.event_types << value unless value.nil?
          end

          event.target_audience = []
          attr['audiences']&.each { |audience| event.keywords << audience['name'] }

          event.host_institutions = []
          attr['host-institutions']&.each { |host| event.host_institutions << host }

          # dictionary fields
          event.eligibility = []
          attr['eligibility']&.each do |key|
            value = convert_eligibility(key)
            event.eligibility << value unless value.nil?
          end

          # add event to events array
          add_event(event)
          @ingested += 1
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
          Sentry.capture_exception(e)
        end
      end
    end
  end
end
