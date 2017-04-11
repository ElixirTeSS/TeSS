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
        if text
          output[text] = line['name']
        end
      end
      line['translations'].each do |alt|
        text = clean_text(alt[1])
        if text
          output[text] = line['name']
        end
      end
    end

    File.open(File.join(Rails.root, 'config', 'data', 'country_synonyms.json'), 'w+') do |f|
      f.write(JSON.generate(output))
    end

  end

end

def clean_text(text)
  if text.respond_to?(:parameterize)
    text = text.parameterize.underscore.humanize.downcase
    if text.length > 0
      return text
    end
  end
  return nil
end
