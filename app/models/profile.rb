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
      text :experience
      text :location
    end
    # :nocov:
  end

  validates :firstname, :surname, :description, presence: true, if: :public?
  validates :website, :orcid, url: true, http_url: true, allow_blank: true
  validate :valid_orcid

  def full_name
    "#{firstname} #{surname}".strip
  end

  def valid_orcid
    if !orcid.nil? && !orcid.blank?
      errors.add(:orcid, "invalid domain") unless orcid.to_s.start_with?('https://orcid.org/')
    end
  end

end
