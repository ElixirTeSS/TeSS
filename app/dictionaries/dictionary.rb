class Dictionary
  include Singleton

  def initialize
    @dictionary = load_dictionary
  end

  def lookup(id)
    @dictionary[id]
  end

  # Returns an array: [id, values]
  def lookup_by(key, value)
    @dictionary.select { |id, values| values[key] == value }.to_a.flatten
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
    if existing
      d = @dictionary.select { |key, value| existing.include?(key) }
    else
      d = @dictionary
    end

    d.map do |key, value|
      [value['title'], key]
    end
  end

  def values_for_search(keys)
    @dictionary.select { |key, value| keys.include?(key) }.map { |key, value| value['title'] }
  end

  private

  def load_dictionary
    YAML.safe_load(File.read(dictionary_filepath)).with_indifferent_access
  end
end
