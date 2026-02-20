class Person < ApplicationRecord
  include HasOrcid

  belongs_to :profile, optional: true
  belongs_to :resource, polymorphic: true

  validates :resource, :role, :full_name, presence: true

  # Automatically link to profile based on ORCID on save
  before_save :link_to_profile_by_orcid

  # Return the display name - currently just the full_name
  def display_name
    full_name
  end

  private

  # Automatically link to a Profile if one exists with a matching ORCID
  def link_to_profile_by_orcid
    if orcid.blank?
      self.profile = nil
    else
      matching_profile = Profile.find_by(orcid: orcid)
      self.profile = matching_profile if matching_profile.present?
    end
  end
end
