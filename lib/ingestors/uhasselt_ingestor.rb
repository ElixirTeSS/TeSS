require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class UhasseltIngestor < Ingestor
    def self.config
      {
        key: 'uhasselt_event',
        title: 'UHasselt Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_uhasselt(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_uhasselt(url)
      uhasselt_url = 'https://bibliotheek.uhasselt.be/nl/resources#kalender'
      event_page = Nokogiri::HTML5.parse(open_url(uhasselt_url.to_s, raise: true)).css("table[summary='RDM training activitites at Hasselt University']").css('tr')
      event_page.each do |el|
        if el.get_attribute('bgcolor') || el.css('td').length < 9
          next
        end

        event = OpenStruct.new

        # date
        date_el = el.css('td')[0]
        if date_el&.text
          date_el = date_el.css('p')[0]
          time_list = date_el.css('p')[1].text.strip.sub('(', '').sub(')', '').split('-')
          start_hours = time_list[0]
          end_hours = time_list[1]
        else
          start_hours = 9
          end_hours = 17
        end
        date_s = date_el.text.strip.split('/')
        if date_s.length == 1
          next
        end
        start_date = "#{date_s[1]}/#{date_s[0]} #{start_hours}:00".to_time
        end_date = "#{date_s[1]}/#{date_s[0]} #{end_hours}:00".to_time
        if start_date < Date.today - 2.months
          start_date += 1.year
          end_date += 1.year
        end
        event.start = start_date
        event.end = end_date
        event.set_default_times

        # title & description
        title_el = el.css('td')[1]
        if title_el&.text
          url = uhasselt_url
          title = title_el.text
        elsif title_el&.css('a')&.first&.text
          url = title_el&.css('a')&.first&.get_attribute('href')
          title = title_el&.css('a')&.first&.text
        elsif title_el&.css('a')&.first&.css('#text').length
          url = title_el&.css('a')&.first&.get_attribute('href')
          title = ''
          title_el&.css('a')&.first&.css('#text').each do |e|
            title += e.text.strip + ' '
          end
          title = title.strip
        else
          next
        end
        event.title = title
        event.url = url

        # location
        location_el = el.css('td')[5]
        location = ''
        location_el.css(h5).each do |e|
          location += e.text.strip + ' '
        end
        location = location.strip
        event.location = location

        event.source = 'UHasselt'
        event.timezone = 'Amsterdam'

        add_event(event)
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end

def recursive_date_func(css, res='')
  if css.length == 1
    res += css.text.strip
  else
    css.each do |css2|
      res += recursive_description_func(css2, res)
    end
  end
  res
end
