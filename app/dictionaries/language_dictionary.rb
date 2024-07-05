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

  def render_language_name(code)
    # I18nData lookup wants uppercase key
    # TODO: is capitalized a good choice for all locales?
    i18ndata_code = code.to_s.upcase
    I18nData.languages(I18n.locale)[i18ndata_code].capitalize
  end

  private

  def dictionary_filepath
    get_file_path 'language', DEFAULT_FILE
  end


end
