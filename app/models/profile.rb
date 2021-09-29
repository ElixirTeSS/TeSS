require 'uri'

class Profile < ApplicationRecord
  belongs_to :user, inverse_of: :profile

  validates :firstname, :surname, :description, presence: true, if: :public?
  validates :website, :orcid, url: true, http_url: true, allow_blank: true
  validate :valid_orcid
  clean_array_fields(:expertise_academic, :expertise_technical, :interest, :activity, :language, :social_media)
  update_suggestions(:expertise_technical, :interest)

  extend FriendlyId
  friendly_id :full_name, use: :slugged

  after_update_commit :reindex
  after_destroy_commit :reindex

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      # full text search fields
      text :firstname
      text :surname
      text :description
      # sort title
      string :sort_title do
        full_name.downcase
      end
      # other fields
      integer :user_id
      string :full_name
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
    field_list = %w( full_name )
  end

  def full_name
    "#{firstname} #{surname}".strip
  end

  def valid_orcid
    if !orcid.nil? && !orcid.blank?
      errors.add(:orcid, "invalid domain") unless orcid.to_s.start_with?('https://orcid.org/')
    end
  end

  def type
    'trainer' if :public
    'profile' if !:public
  end

  def reindex
    if Rails.env.production?
      Trainer.reindex
    end
  end

  def should_generate_new_friendly_id?
    firstname_changed? or surname_changed?
  end

end
