module HasDifficultyLevel

  extend ActiveSupport::Concern

  included do
    validates :difficulty_level, controlled_vocabulary: { dictionary: 'DifficultyDictionary' }

    # :nocov:
    searchable if: -> (_) { TeSS::Config.solr_enabled } do
      string :difficulty_level do
        DifficultyDictionary.instance.lookup_value(self.difficulty_level, 'title')
      end
    end
    # :nocov:
  end

  # Allows setting of the difficulty level by ID or title
  def difficulty_level=(id_or_title)
    id = DifficultyDictionary.instance.lookup_by('title', id_or_title)&.first

    super(id || id_or_title)
  end

end
