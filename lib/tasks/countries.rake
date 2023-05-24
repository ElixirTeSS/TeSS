# frozen_string_literal: true

require 'json'
require 'httparty'

namespace :tess do
  desc 'Get a list of country synonyms from restcountries.eu'
  task get_country_synonyms: :environment do
    url = 'https://restcountries.eu/rest/v2/all'
    response = HTTParty.get(url)
    countries = response.parsed_response
    output = {}

    # Use both alternate names and translations
    countries.each do |line|
      line['altSpellings'].each do |alt|
        text = clean_text(alt)
        output[text] = line['name'] if text
      end
      line['translations'].each do |alt|
        text = clean_text(alt[1])
        output[text] = line['name'] if text
      end
    end

    File.open(File.join(Rails.root, 'config', 'data', 'country_synonyms.json'), 'w+') do |f|
      f.write(JSON.generate(output))
    end
  end

  desc 'Attempt to correct country names for all existing event countries'
  task fix_current_countries: :environment do
    puts 'Checking for countries...'
    COUNTRY_SYNONYMS = JSON.parse(File.read(File.join(Rails.root, 'config', 'data', 'country_synonyms.json')))
    puts "#{Event.all.length} events to check."
    count = 0
    Event.all.each do |event|
      puts "Checking: #{event.title}"
      unless event.country
        puts "No country for: #{event.title}"
        next
      end
      next unless event.country.respond_to?(:parameterize)

      text = event.country.parameterize.underscore.humanize.downcase
      next unless COUNTRY_SYNONYMS[text]

      puts "#{event.title}: Changing #{text} -> #{COUNTRY_SYNONYMS[text]}"
      event.country = COUNTRY_SYNONYMS[text]
      event.save
      count += 1
    end
    puts "Updated #{count} countries out of #{Event.all.length}"
  end
end

def clean_text(text)
  if text.respond_to?(:parameterize)
    text = text.parameterize.underscore.humanize.downcase
    return text if text.length.positive?
  end
  nil
end
