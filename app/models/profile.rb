require 'uri'

class Profile < ApplicationRecord
  belongs_to :user, inverse_of: :profile

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      text :firstname
      text :surname
      text :website
      text :email
      text :image_url
      time :updated_at
      # trainer profile fields
      boolean :public
      text :description
      text :location
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
    end
    # :nocov:
  end

  validates :firstname, :surname, :description, presence: true, if: :public?
  validates :website, :orcid, url: true, http_url: true, allow_blank: true
  validate :valid_orcid
  clean_array_fields(:expertise_academic, :expertise_technical, :interest, :activity, :language, :social_media)
  update_suggestions(:expertise_technical, :interest)

  def full_name
    "#{firstname} #{surname}".strip
  end

  def valid_orcid
    if !orcid.nil? && !orcid.blank?
      errors.add(:orcid, "invalid domain") unless orcid.to_s.start_with?('https://orcid.org/')
    end
  end

end
