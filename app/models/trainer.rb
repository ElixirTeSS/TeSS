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
      string :sort_title do
        full_name.downcase
      end
      integer :user_id
      string :full_name
      text :firstname
      text :surname
      text :description
      string :location
      string :orcid
      string :experience do
        TrainerExperienceDictionary.instance.lookup_value(self.experience, 'title')
      end
      string :expertise_academic, multiple: true
      string :expertise_technical, multiple: true
      string :interest, multiple: true
      string :activity, multiple: true
      string :language, multiple: true
      string :social_media, multiple: true
      time :updated_at
      boolean :public
    end
    # :nocov:
  end

  def self.facet_fields
    field_list = %w( location experience expertise_academic expertise_technical interest activity language)
  end

  def should_generate_new_friendly_id?
    firstname_changed? or surname_changed?
  end

end
