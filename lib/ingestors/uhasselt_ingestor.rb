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
      event_page = Nokogiri::HTML5.parse(open_url(uhasselt_url.to_s, raise: true)).css("table[summary='RDM training activities at Hasselt University']").first.css('tr')
      event_page.each_with_index do |el, idx|
        if el.css('td').length != 9
          next
        end

        event = OpenStruct.new

        puts "idx: #{idx}"

        # date
        date_el = el.css('td')[0]
        if date_el&.text&.strip.nil?
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
          puts 'next'
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
          title_el&.css('a')&.first&.css('#text').map{ |e| e.text.strip}.join(' ')
        else
          next
        end
        event.title = title.gsub("\n\t\t\t", ' ')
        event.url = url
        puts "title: #{event.title}"
        puts "date: #{event.start}"

        # location
        location = el.css('td')[5].css('h5').map{ |e| e.text.strip}.join(' ')

        event.venue = location
        puts "location: #{event.venue}"

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
