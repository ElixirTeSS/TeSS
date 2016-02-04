module TeSS
  # Dictionary of difficultys from http://licenses.opendefinition.org/licenses/groups/all.json
  # Converted to yaml and saved to config/dictionaries/difficultys.yml

  # Inspired by SEEK's ImageFileDictionary
  # https://github.com/seek4science/seek/blob/master/lib/seek/image_file_dictionary.rb
  class DifficultyDictionary
    include Singleton

    attr_reader :difficulty_names, :difficulty_abbreviations, :difficulty_options_for_select

    def initialize
      @dictionary = difficulty_dictionary_definition
      @difficulty_names = extract_difficulty_names
      @difficulty_abbreviations = @dictionary.keys
      @difficulty_options_for_select = extract_difficulty_options_for_select
    end

    def difficulty_name_for_abbreviation(abbreviation)
      @dictionary[abbreviation]['title']
    end

    def extract_difficulty_names(difficulty_dictionary=@dictionary)
      list = []
      difficulty_dictionary.each do |key,value|
        list << value['title']
      end
      list
    end

    private

    def difficulty_dictionary_definition
      difficulty_dictionary_filepath = File.join(Rails.root, "config", "dictionaries", "difficulty.yml")
      YAML.load(File.read(difficulty_dictionary_filepath))
    end

    # Returns an array of two-element arrays of difficultys ready to be used in options_for_select() for generating option/select tags
    # [['Difficulty 1 full name','Difficulty 1 abbreviation'], ['Difficulty 2 full name','Difficulty 2 abbreviation'], ...]
    def extract_difficulty_options_for_select
      list = []
      @difficulty_abbreviations.each do |abbr|
        list << [difficulty_name_for_abbreviation(abbr), abbr]
      end
      return list
    end

  end
end