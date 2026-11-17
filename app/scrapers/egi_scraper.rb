# frozen_string_literal: true

require 'nokogiri'
require 'date'
require 'time'
require 'uri'

class EgiScraper
  EGI_WEBSITE_BASE_URL = 'https://www.egi.eu'
  SOURCE_URL = "#{EGI_WEBSITE_BASE_URL}/trainings-and-webinars"

  MONTHS = Date::MONTHNAMES.compact.freeze

  def initialize(html)
    @doc = Nokogiri::HTML(html)
  end

  def events
    @events ||= extract_events
    Rails.logger.info("[EGI scraper] Loaded #{@events.length} training events")
    @events
  end

  def materials
    @materials ||= extract_training_materials
    Rails.logger.info("[EGI scraper] Loaded #{@materials.length} training materials")
    @materials
  end

  private

  def extract_events
   Rails.logger.info("[EGI scraper] Starting the extraction of *Training Events*... [IN PROGRESS]\n")

   links = @doc.css('a[href^="/event/"]')
   Rails.logger.info("EGI Web: found #{links.length} event links")

   events = links.filter_map do |link|
     url = absolute_url(link['href'])
     next unless url

     text = clean_text(link.text)
     next unless text

     start_time = extract_datetime(text)
     next unless start_time

     event = {
       title: event_title(link),
       description: event_description(link, text),
       url: url,
       start: start_time
     }

     event
   end

   unique_events = events.uniq { |event| event[:url] }

   Rails.logger.info('===============================================')
   Rails.logger.info("EGI Web: extracted #{events.length} events")
   Rails.logger.info("EGI Web: unique events #{unique_events.length}")
   Rails.logger.info('===============================================')

   unique_events.sort_by { |event| event[:start] }.reverse
   rescue StandardError => e
     Rails.logger.error("Error extracting events: #{e.class}: #{e.message}")
     Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
    raise
  end


  def extract_training_materials
    Rails.logger.info("[EGI scraper] Starting the extraction of *Training Materials*... [IN PROGRESS]\n")

    links = @doc.css('a[href^="/service/"]')
    Rails.logger.info(
      "[EGI Scraper] Found #{links.length} potential material links"
    )

    extracted_materials = links.filter_map do |link|
      url = absolute_url(link['href'])
      title = clean_text(link['href'])
      description = clean_text(link.at_css('p')&.text)

      if title.nil? || url.nil?
        Rails.logger.warn(
          "[EGI Scraper] Skipping material: " \
          "title=#{title.inspect}, url=#{url.inspect}"
        )
        next
      end

      material = {
        title: title,
        description: description,
        url: url
      }

      Rails.logger.info(
        "[EGI Scraper] " \
        "title=#{material[:title].inspect}, url=#{material[:url]}"
      )

      material    
    end

    unique_materials = extracted_materials.uniq { |material| material[:url] }

    Rails.logger.info(
      "[EGI Scraper] Materials summary: " \
      "extracted=#{extracted_materials.length}, " \
      "unique=#{unique_materials.length}, " \
      "duplicates_removed=#{extracted_materials.length - unique_materials.length}"
    )

    unique_materials
  end

  def event_title(link)
    title = clean_text(link['title'])
    return title if title

    text = clean_text(link.text)
    return text unless text

    # Remove the appended date/time from the fallback title.
    text.sub(
      /\b\d{1,2}\s+
       (January|February|March|April|May|June|July|August|September|October|November|December)
       \s+\d{4}
       .*?\b(?:CET|CEST)\b/ix,
      ''
    ).strip
  end

  def event_description(link, text)
    title = clean_text(link['title'])

    return text unless title

    description = text.sub(/\A#{Regexp.escape(title)}/, '')
    description = description.sub(
      /\b\d{1,2}\s+
       (January|February|March|April|May|June|July|August|September|October|November|December)
       \s+\d{4}
       .*?\b(?:CET|CEST)\b/ix,
      ''
    )

    clean_text(description) || text
  end

  def extract_datetime(text)
    return nil unless text

    match = text.match(
      /(\d{1,2})\s+
       (January|February|March|April|May|June|July|August|September|October|November|December)
       \s+(\d{4})
       (?:
         .*?
         (\d{1,2}):(\d{2})
         \s*(CET|CEST)?
       )?/ix
    )

    return nil unless match

    day = match[1].to_i
    month = month_number(match[2])
    year = match[3].to_i
    hour = (match[4] || '00').to_i
    minute = (match[5] || '00').to_i
    zone = match[6]

    return nil unless month
    return nil unless year.between?(2000, 2100)
    return nil unless valid_time?(hour, minute)

    Time.new(
      year,
      month,
      day,
      hour,
      minute,
      0,
      timezone_offset(zone)
    )
  rescue ArgumentError
    nil
  end

  def month_number(month)
    MONTHS.index { |name| name.casecmp?(month) }&.+(1)
  end

  def valid_time?(hour, minute)
    hour.between?(0, 23) && minute.between?(0, 59)
  end

  def timezone_offset(zone)
    case zone&.upcase
    when 'CEST'
      '+02:00'
    when 'CET'
      '+01:00'
    else
      '+01:00'
    end
  end

  def absolute_url(url)
    return nil if url.nil?

    value = url.to_s.strip
    return nil if value.empty?

    URI.join(EGI_WEBSITE_BASE_URL, value).to_s
  rescue URI::InvalidURIError
    nil
  end

  def clean_text(text)
    return nil if text.nil?

    value = text.to_s.gsub(/\s+/, ' ').strip
    value.empty? ? nil : value
  end
end
