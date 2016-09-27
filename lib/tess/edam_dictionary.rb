module TeSS
  class EdamDictionary < Dictionary

    attr_reader :edam_names, :edam_names_for_autocomplete

    def initialize
      @dictionary = edam_dictionary_definition
      @edam_names = extract_edam_names
      @edam_names_for_autocomplete = extract_edam_names_for_autocomplete
    end

    def extract_edam_names(edam_dictionary=@dictionary)
      list = []
      edam_dictionary.each do |value|
        list << value['preferred_label']
      end
      list.sort!
    end

    private

    def edam_dictionary_definition
      edam_dictionary_filepath = File.join(Rails.root, 'config', 'dictionaries', 'edam.yml')
      YAML.load(File.read(edam_dictionary_filepath))
    end

    # Provide the necessary output for jquery.autocomplete
    def extract_edam_names_for_autocomplete
      list = []
      @edam_names.each do |name|
        list << {'value' => name, 'data' => name}
      end
      return list
    end

  end
end