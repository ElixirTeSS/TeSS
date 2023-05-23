# frozen_string_literal: true

# Base dictionary class
class Dictionary
  include Singleton
  include TrigramSimilarity

  delegate :keys, :each_key, to: :@dictionary

  def initialize
    @dictionary = load_dictionary
  end

  def reload
    @dictionary = load_dictionary
  end

  def lookup(id)
    @dictionary[id]
  end

  # Find by id, or by case-insensitive fuzzy matching
  def best_match(id)
    return id if @dictionary.key? id

    best_score = 0
    best_key = nil

    @dictionary.each do |k, v|
      v.fetch('match', []).append(k).each do |option|
        score = similarity(id, option)
        if score > best_score
          best_key = k
          best_score = score
        end
      end
    end
    return best_key if best_score > 0.3
  end

  # Returns an array: [id, values]
  def lookup_by(key, value)
    @dictionary.select { |_id, values| values[key] == value }.to_a.flatten
  end

  # Find the value for the given key, for the given entry.
  # Returns nil if no entry found or the entry doesn't contain that key.
  #  e.g.
  #    LicenceDictionary.instance.lookup_value('GPL-3.0', 'title') => "GNU General Public License 3.0"
  #    LicenceDictionary.instance.lookup_value('GPL-3.0', 'fish') => nil
  #    LicenceDictionary.instance.lookup_value('fish', 'title') => nil
  #    LicenceDictionary.instance.lookup_value('fish', 'fish') => nil
  #
  def lookup_value(id, key)
    lookup(id).try(:[], key)
  end

  def options_for_select(existing = nil)
    d = if existing
          @dictionary.select { |key, _value| existing.include?(key) }
        else
          @dictionary
        end

    d.map do |key, value|
      if value['description'].nil?
        [value['title'], key, '']
      else
        [value['title'], key, value['description']]
      end
    end
  end

  def values_for_search(keys)
    @dictionary.select { |key, _value| keys.include?(key) }.map { |_key, value| value['title'] }
  end

  private

  def load_dictionary
    YAML.safe_load(File.read(dictionary_filepath)).with_indifferent_access
  end

  def get_file_path(config_file, default_file)
    begin
      result = File.join(Rails.root, 'config', 'dictionaries', TeSS::Config.dictionaries[config_file])
      raise 'file not found' unless File.file?(result)
    rescue StandardError
      result = File.join(Rails.root, 'config', 'dictionaries', default_file)
    end
    result
  end
end
