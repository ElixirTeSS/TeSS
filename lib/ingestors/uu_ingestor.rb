require 'icalendar'
require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class UuIngestor < Ingestor
    def self.config
      {
        key: 'uu_event',
        title: 'UU Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_uu(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_uu(url)
      # instead of fetching all content at the same time we have to make a loop
      # over the categories, since in the RSS feed there is no information
      # on which category an event belongs to.
      # translate here only to the names given on the UU site, use the event_types match field
      # to further match those.
      categories = {
        # en
        4301 => 'workshops, masterclasses',
        4296 => 'lectures',
        4295 => 'training',
        4293 => 'congresses, symposia',
        2162490 => 'workshops, masterclasses', # not really sure what this should be
        # nl
        4043 => 'workshops, masterclasses',
        1_916_692 => 'lectures', # lezingen, debatten,
        1_916_689 => 'training', # cursussen, trainingen
        174_593 => 'congressen, symposia'
      }

      url.split('=').last.split(',').each do |category_id|
        sub_url = url.split('=').first + '=' + category_id
        docs = Nokogiri::XML(open_url(sub_url, raise: true)).xpath('//item')
        docs.each do |event_item|
          begin
            event = OpenStruct.new
            event.event_types = [categories.fetch(category_id, 'workshops_and_courses')]
            event_item.element_children.each do |element|
              case element.name
              when 'title'
                event.title = element.text
              when 'link'
                event.url = element.text
              when 'creator'
                # event.creator = element.text
                # no creator field. Not sure needs one
              when 'description'
                event.description = convert_description element.text
              when 'location'
                event.venue = element.text
                loc = element.text.split(',')
                event.city = loc.first.strip
                event.country = loc.last.strip
              when 'provider'
                event.organizer = element.text
              # ugly implementation so that TeSS does not shift timezone too much
              when 'startdate', 'courseDate'
                event.start = element.text.to_s.split
                event.start = event.start[0, event.start.length - 1].join(' ').to_time
              when 'enddate', 'courseEndDate'
                event.end = element.text.to_s.split
                event.end = event.end[0, event.end.length - 1].join(' ').to_time
              when 'latitude'
                event.latitude = element.text
              when 'longitude'
                event.longitude = element.text
              when 'pubDate'
                # Not really needed
              else
                # chuck away
              end
            end
          end
          # fetch the ICS file to get the date and location info
          nid = event_item.xpath('guid').text
          if nid
            ics_url = "https://www.uu.nl/node/#{nid}/ics"
            ical_event = Icalendar::Event.parse(open_url(ics_url, raise: true).set_encoding('utf-8')).first
            event.start ||= ical_event.dtstart
            event.end ||= ical_event.dtend
            event.venue ||= ical_event.location
            unless Rails.env.test?
              sleep 1
            end
          end

          event.set_default_times
          event.source = 'UU'
          event.timezone = 'Amsterdam'

          # the below code allows fetching the long description, at the cost of a
          # page load per event.
          # Now fetch the page to get the event date (until it is added to the RSS feed)
          # if event.url.starts_with('https://')
          # should we do more against data exfiltration? URI.open is a known hazard
          # page = Nokogiri::XML(URI.open(event.url))
          # event.description = convert_description page.css('.content-block__inner').first.inner_html
          # end
          add_event(event)
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end
    end
  end
end
