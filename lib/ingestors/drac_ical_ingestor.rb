module Ingestors
  class DracIcalIngestor < IcalIngestor
    attr_reader :default_timezone

    def self.config
      {
        key: 'drac_ical',
        title: 'DRAC iCalendar',
        category: :events
      }
    end

    private

    def full_url(url)
      # Don't append '?ical=true' to URL
      url
    end

    def fetch_events(file_url)
      # Fetch once, read twice
      fetched = open_url(file_url, raise: true).set_encoding('utf-8')

      # Note, each Calendar has events associated with it, but there may be
      # ics files that have events and no calendar ...
      icalendar = Icalendar::Calendar.parse(fetched)
      @default_timezone = icalendar&.first&.custom_properties&.fetch('x_wr_timezone')&.first

      fetched.rewind
      Icalendar::Event.parse(fetched)
    end

    def ical_event_online?(calevent)
      # Events are online if location isn't specified
      calevent.location.nil? || calevent.location.downcase.include?('online')
    end

    def extract_url(calevent)
      # ics exported from Google doesn't have a URL field, so ...
      return calevent.url.to_s if calevent.url
      return nil unless calevent.description
      parse_description_url(calevent.description)
    end

    def parse_description_url(description)
      return {} unless description

      link = parse_html_description_url(description)
      if link
        return link
      end

      lines = description.split(/\n/)
      lines.each_with_index do |line, index|
        # URL on same line
        m = line.match(/^(?:Registration form|Register at): (.*)$/)
        unless m.nil?
          return m[1]
        end

        # URL on next line
        m = line.match(/^(?:Registration form|Register at):$/)
        unless m.nil?
          if index < lines.count - 1
            registration_url = lines[index + 1]
            if registration_url.match(/^http/)
              return registration_url
            end
          end
        end
      end

      nil
    end

    def parse_html_description_url(description)
      parsed = Nokogiri::HTML(description)
      links = parsed.search('a')
      links.each do |node|
        if node.inner_html =~ /regist/i
          return node.attributes['href'].value
        end
      end

      return links[0].attributes['href'].value if !links.empty?
      return nil
    end

    def extract_event_timezone(calevent)
      timezone = super(calevent)
      timezone ||= default_timezone

      case timezone
      when nil
        return
      when /Toronto/
	      return 'Eastern Time (US & Canada)'
      when /Vancouver/
	      return 'Pacific Time (US & Canada)'
      when /Edmonton/
	      return 'Mountain Time (US & Canada)'
      end

      timezone
    end
  end
end
