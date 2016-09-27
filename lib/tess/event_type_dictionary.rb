module TeSS

  class EventTypeDictionary
    include Singleton

    def initialize
      @dictionary = event_type_dictionary_definition
    end

    def options_for_select(existing = nil)
      if existing
        d = @dictionary.select { |key, value| existing.include?(key) }
      else
        d = @dictionary
      end

      d.map do |key, value|
        [value['title'], key]
      end
    end

    def lookup(key)
      @dictionary[key]
    end

    private

    def event_type_dictionary_definition
      event_type_dictionary_filepath = File.join(Rails.root, "config", "dictionaries", "event_types.yml")
      YAML.load(File.read(event_type_dictionary_filepath))
    end

  end
end