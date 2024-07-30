# Dictionary of Languages
class LanguageDictionary < Dictionary
  # Not really a dictionary (an array) ...
  def initialize
    @dictionary = TeSS::Config.languages
  end

  def lookup(id)
    @dictionary.find { |v| v == id }
  end

  # Override because we want this in the viewers language ...
  def options_for_select(existing = nil)
    d = if existing
          @dictionary.select { |key| existing.include?(key) }
        else
          @dictionary
        end

    d.map { |key| [render_language_name(key), key, key] }
  end

  def values_for_search(keys)
    return unless keys

    @dictionary.select { |key| keys.include?(key) }
               .map { |key| render_language_name(key) }
  end

  def render_language_name(code)
    i18ndata_code = code.to_s.upcase
    I18n.t("languages.#{code.to_s.downcase}",
           default: I18nData.languages(I18n.locale)[i18ndata_code]&.capitalize)
  end
end
