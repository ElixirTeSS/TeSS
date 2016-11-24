module Tess
  # Dictionary of timezones https://timezonedb.com/download
  # Converted to yaml and saved to config/dictionaries/timezones.yml
  # Conversion script is scripts/convert_timezones.rb
  class TimezoneDictionary < Dictionary

    private

    def dictionary_filepath
      File.join(Rails.root, "config", "dictionaries", "timezones.yml")
    end

  end
end