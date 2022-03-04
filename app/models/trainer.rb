require 'i18n_data'

# define model for Trainer as subset of Profile
class Trainer < Profile

  after_update_commit :reindex
  after_destroy_commit :reindex

  extend FriendlyId
  friendly_id :full_name, use: :slugged

  include Searchable

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      # full text search fields
      text :full_name
      text :description
      text :location
      text :expertise_technical do
        expertise_technical.to_s
      end
      text :expertise_academic do
        expertise_academic.to_s
      end
      text :interest do
        interest.to_s
      end
      text :activity do
        activity.to_s
      end
      text :language do
        langs = []
        language.each { |key| langs << language_label_by_key(key) }
        langs.join ', '
      end
      # sort title
      string :sort_title do
        full_name.downcase
      end
      # other fields
      integer :user_id
      string :firstname
      string :surname
      string :location
      string :orcid
      string :experience do
        TrainerExperienceDictionary.instance.lookup_value(self.experience, 'title')
      end
      string :expertise_academic, multiple: true
      string :expertise_technical, multiple: true
      string :fields, multiple: true
      string :interest, multiple: true
      string :activity, multiple: true
      string :language, multiple: true do
        languages_from_keys(self.language)
      end
      string :social_media, multiple: true
      time :updated_at
      boolean :public
    end
    # :nocov:
  end

  def self.facet_fields
    field_list = %w( location experience expertise_academic expertise_technical
                     fields interest activity language )
  end

  def should_generate_new_friendly_id?
    firstname_changed? or surname_changed?
  end

  def language_label_by_key(key)
    if key and !key.nil?
      I18nData.languages.each do |lang|
        return lang[1] if lang[0] == key
      end
    end
  end

  def languages_from_keys(keys)
    labels = []
    keys.each { |key| labels << language_label_by_key(key) }
    return labels
  end

  def self.finder_needs_type_condition?
    true
  end

end
