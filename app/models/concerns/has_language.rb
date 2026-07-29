module HasLanguage

  extend ActiveSupport::Concern

  included do
    validates :language, controlled_vocabulary: { dictionary: 'LanguageDictionary', allow_blank: true }

    model = self
    if TeSS::Config.solr_enabled
      # :nocov:
      searchable do
        string :language, multiple: model.columns_hash['language'].array? do
          # LanguageDictionary.instance.lookup(self.language)
          self.language
        end
      end
      # :nocov:
    end
  end

end
