# Dictionary of Languages
class LanguageDictionary < Dictionary

  DEFAULT_FILE = 'language.yml'

  # Override because we want this in the viewers language ...
  def options_for_select(existing = nil)
    d = if existing
          @dictionary.select { |key, _value| existing.include?(key) }
        else
          @dictionary
        end

    d.map do |key, _value|
      [render_language_name(key), key, key]
    end
  end

  def values_for_search(keys)
    return unless keys
    @dictionary.select { |key, _value| keys.include?(key) }.
      map { |key, _value| render_language_name(key) }
  end

  private

  def dictionary_filepath
    get_file_path 'language', DEFAULT_FILE
  end

  def render_language_name(code)
    I18n.t("dictionaries.languages.#{code}")
  end

end
