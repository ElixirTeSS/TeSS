module TeSS
  # Dictionary of licences from http://licenses.opendefinition.org/licenses/groups/all.json
  # Converted to yaml and saved to config/dictionaries/licences.yml
  class LicenceDictionary
    include Singleton

    attr_reader :licence_names, :licence_abbreviations, :licence_options_for_select

    def initialize
      @dictionary = licence_dictionary_definition
      @licence_names = extract_licence_names
      @licence_abbreviations = @dictionary.keys
      @licence_options_for_select = extract_licence_options_for_select
    end

    def licence_name_for_abbreviation(abbreviation)
      @dictionary[abbreviation]['title']
    end

    def licence_url_for_abbreviation(abbreviation)
      @dictionary[abbreviation]['url']
    end

    def extract_licence_names(licence_dictionary=@dictionary)
      list = []
      licence_dictionary.each do |key,value|
        list << value['title']
      end
      list
    end

    private

    def licence_dictionary_definition
      licence_dictionary_filepath = File.join(Rails.root, "config", "dictionaries", "licences.yml")
      YAML.load(File.read(licence_dictionary_filepath))
    end

    # Returns an array of two-element arrays of licences ready to be used in options_for_select() for generating option/select tags
    # [['Licence 1 full name','Licence 1 abbreviation'], ['Licence 2 full name','Licence 2 abbreviation'], ...]
    def extract_licence_options_for_select
      list = []
      @licence_abbreviations.each do |abbr|
        list << [licence_name_for_abbreviation(abbr), abbr]
      end
      return list
    end

  end
end