module HasLanguage

  extend ActiveSupport::Concern

  included do
    validates :language, controlled_vocabulary: { dictionary: 'LanguageDictionary',
                                                  allow_nil: true }

    if TeSS::Config.solr_enabled
      # :nocov:
      searchable do
        string :language do
          # LanguageDictionary.instance.lookup(self.language)
          self.language
        end
      end
      # :nocov:
    end
  end

end
