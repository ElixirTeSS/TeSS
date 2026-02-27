require 'icalendar'
require 'nokogiri'
require 'open-uri'
require 'tzinfo'

module Ingestors
  module Heptraining
    class GrayScottIngestor < Ingestor
      def self.config
        {
          key: 'gray_scott_event',
          title: 'Gray Scott Events API',
          category: :events
        }
      end

      def read(url)
        @verbose = false
        process_gray_scott(url)
      end

      private

      def process_gray_scott(url)
        events = Icalendar::Event.parse(open_url(url, raise: true).set_encoding('utf-8'))
        raise 'Not found' if events.nil? || events.empty?

        events.each do |e|
          process_calevent(e, url)
        end
      end

      def process_calevent(calevent, url)
        # puts "calevent: #{calevent.inspect}"
        gs_url = calevent.custom_properties.find { |key, _| key.include?('http') }&.last&.first&.strip&.gsub(%r{^[/\s]+|[/\s]+$}, '')&.prepend('https://')
        html = get_html_from_url(get_redirected_url(gs_url))

        event = OpenStruct.new
        event.title = calevent.summary.to_s
        event.url = gs_url
        event.description = html.css('.paragraphStyle').text.strip || calevent.description.to_s

        event.end = calevent.dtend&.to_time
        unless calevent.dtstart.nil?
          dtstart = calevent.dtstart
          event.start = dtstart&.to_time
          tzid = dtstart.ical_params['tzid']
          event.timezone = tzid.first.to_s if !tzid.nil? && tzid.size.positive?
        end
        event.venue = clean_html(calevent.location.to_s)
        event.organizer = html.css('h3:contains("Speakers") + ul li a')&.map(&:text)&.map(&:strip)&.join(', ') # coma separated if multiple speakers

        @events << event
      end

      def get_redirected_url(url)
        uri = URI.parse(url)
        label = CGI.parse(uri.query)['label']&.first

        script_content = get_html_from_url(url).css('script').find { |s| s.content.include?('var dictReference') }&.content
        dict_match = script_content&.match(/var\s+dictReference\s*=\s*({[^}]+})/)
        return unless dict_match

        dict = JSON.parse(dict_match[1])
        matched_value = dict[label]

        "#{uri.scheme}://#{uri.host}#{uri.path.sub(%r{/[^/]+$}, '')}/#{matched_value}"
      end

      def clean_html(html)
        Nokogiri::HTML::DocumentFragment.parse(html).text.strip
      end
    end
  end
end
