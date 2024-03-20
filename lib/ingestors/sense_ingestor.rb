# frozen_string_literal: true

require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class SenseIngestor < Ingestor
    def self.config
      {
        key: 'sense_event',
        title: 'Sense Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_sense(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_sense(url)
      (1..2).each do |i|
        url = "https://sense.nl/event/page/#{i}"
        sleep(1) unless Rails.env.test? && File.exist?('test/vcr_cassettes/ingestors/sense.yml')
        event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css("div[class='event-list-part']")[0].css("div[class='upcoming-event-box']")
        event_page.each do |event_data|
          event = OpenStruct.new

          event.url = event_data.css('a')[0].get_attribute('href')

          event_page2 = Nokogiri::HTML5.parse(open_url(event.url.to_s, raise: true)).css("div[class='news-banner-content']")[0]
          event.title = event_page2.css('h1')[0].text.strip
          location = nil
          date = nil
          time = nil
          event_page2.css("ul[class='dissertation-meta-info']")[0].css('li').each do |li|
            case li.css('label').text.strip
            when 'Date'
              date = li.css('span').text.strip
            when 'Time'
              time = li.css('span').text.strip
            when 'Location'
              location = li.css('span').text.strip
            end
          end
          event.venue = location
          time ||= nil
          times = date_parsing(date, time)
          event.start = times[0]
          event.end = times[1]

          event.source = 'Sense'
          event.timezone = 'Amsterdam'
          event.set_default_times

          add_event(event)
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end
    end
  end
end

def date_parsing(date, time)
  if time.nil?
    date_parsing_without_time(date)
  else
    date_parsing_with_time(date, time)
  end
end

def date_parsing_with_time(date, time)
  times = time.split('-')
  d = Date.parse(date)
  ts = times.map { |t| Time.zone.parse(t) }
  start_time = DateTime.new(d.year, d.month, d.day, ts[0].hour, ts[0].min)
  end_time = DateTime.new(d.year, d.month, d.day, ts[1].hour, ts[1].min)
  [start_time, end_time]
end

def date_parsing_without_time(date)
  dates = date.split('-')
  ds = [nil, nil]
  ds[1] = Date.parse(dates[1])
  start_list = [nil, nil, nil]
  end_list = dates[1].strip.split(' ')
  dates[0].strip.split(' ').each_with_index.map { |x, i| start_list[i] = x }
  start_list.each_with_index do |_x, i|
    start_list[i] ||= end_list[i]
  end
  d = Time.zone.parse(start_list.join(' '))
  start_time = DateTime.new(d.year, d.month, d.day, 9)
  d = Time.zone.parse(end_list.join(' '))
  end_time = DateTime.new(d.year, d.month, d.day, 17)
  [start_time, end_time]
end
