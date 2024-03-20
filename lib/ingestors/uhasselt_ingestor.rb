# frozen_string_literal: true

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
      event_page.each_with_index do |el, _idx|
        next if el.css('td').length != 9

        event = OpenStruct.new

        # date
        datetime_text = el.css('td')[0].text.gsub("\n", '').gsub("\t", '').strip
        if datetime_text.include?('(')
          datetime_list = datetime_text.split('(')
          date_text = datetime_list[0].strip
          time_text = datetime_list[1].gsub(')', '').strip
          time_list = time_text.split('-')
          start_hours = time_list[0]
          end_hours = time_list[1]
        else
          date_text = datetime_text
          start_hours = 9
          end_hours = 17
        end
        date_s = date_text.split('/')
        next if date_s.length == 1

        start_date = Time.zone.parse("#{date_s[1]}/#{date_s[0]} #{start_hours}:00")
        end_date = Time.zone.parse("#{date_s[1]}/#{date_s[0]} #{end_hours}:00")
        if start_date < Time.zone.now - 2.months
          start_date += 1.year
          end_date += 1.year
        end

        event.start = start_date
        event.end = end_date
        event.set_default_times

        # location
        location = el.css('td')[5].css('h5').map { |e| e.text.strip }.join(' ')
        event.venue = location

        # title & description
        title_el = el.css('td')[1]
        url = title_el&.css('a')&.first&.get_attribute('href')&.gsub(' ', '') || uhasselt_url
        if title_el&.text
          title = title_el.text
        elsif title_el&.css('a')&.first&.text
          title = title_el&.css('a')&.first&.text
        elsif title_el&.css('a')&.first&.css('#text')&.length
          title = title_el&.css('a')&.first&.css('#text')&.map { |e| e.text.strip }&.join(' ')
        else
          next
        end
        # weird case where multiple types of space character where used in same title
        event.title = title.gsub("\n\t\t\t", ' ').strip.chars.map { |ch| ch.ord == 160 ? ' ' : ch }.join('')
        hash = "#{event.title}#{event.start.strftime('%y%m%d')}#{event.venue}".gsub(' ', '').strip.chars.filter { |ch| ch.to_i(36).positive? || (ch == '0') }.join('')
        event.url = "#{url.split('#').first}##{hash}"

        event.source = 'UHasselt'
        event.timezone = 'Amsterdam'

        add_event(event)
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end
