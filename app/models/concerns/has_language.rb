module HasLanguage

  extend ActiveSupport::Concern

  included do
    validates :language, controlled_vocabulary_or_nil: { dictionary: 'LanguageDictionary' }

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
