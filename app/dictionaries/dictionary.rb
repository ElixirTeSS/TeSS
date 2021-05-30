# Base dictionary class
class Dictionary
  include Singleton

  def initialize
    @dictionary = load_dictionary
  end

  def reload
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
      if value['description'].nil?
        [value['title'], key, '']
      else
        [value['title'], key, value['description']]
      end
    end
  end

  def values_for_search(keys)
    @dictionary.select { |key, value| keys.include?(key) }.map { |key, value| value['title'] }
  end

  private

  def load_dictionary
    YAML.safe_load(File.read(dictionary_filepath)).with_indifferent_access
  end

  def get_file_path(config_file, default_file)
    begin
      result = File.join(Rails.root, 'config', 'dictionaries', TeSS::Config.dictionaries[config_file])
      raise 'file not found' if !File.file?(result)
    rescue
      result = File.join(Rails.root, 'config', 'dictionaries', default_file)
    end
    return result
  end
end
