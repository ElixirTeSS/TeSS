module TeSS

  class EligibilityDictionary
    include Singleton

    def initialize
      @dictionary = eligibility_dictionary_definition
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

    def eligibility_dictionary_definition
      eligibility_dictionary_filepath = File.join(Rails.root, "config", "dictionaries", "eligibility.yml")
      YAML.load(File.read(eligibility_dictionary_filepath))
    end

  end
end