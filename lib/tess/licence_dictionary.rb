module TeSS
  # Dictionary of licences from http://licenses.opendefinition.org/licenses/groups/all.json
  # Converted to yaml and saved to config/dictionaries/licences.yml
  class LicenceDictionary
    include Singleton

    def initialize
      @dictionary = licence_dictionary_definition
    end

    def licence_abbreviations
     @dictionary.keys
    end

    def licence_names
      list = []
      @dictionary.each do |key,value|
        list << value['title']
      end
      return list
    end

    def licence_name_for_abbreviation(abbreviation)
      @dictionary[abbreviation]['title']
    end

    def licence_url_for_abbreviation(abbreviation)
      @dictionary[abbreviation]['url']
    end

    private

    def licence_dictionary_definition
      licence_dictionary_filepath = File.join(Rails.root, "config", "dictionaries", "licences.yml")
      YAML.load(File.read(licence_dictionary_filepath))
    end
  end
end