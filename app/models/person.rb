class Person < ApplicationRecord
  include HasOrcid

  belongs_to :profile, optional: true
  belongs_to :resource, polymorphic: true

  validates :resource, :role, presence: true

  # Validate that at least a full_name OR both given_name and family_name are present
  validate :name_presence

  # Automatically link to profile based on ORCID on save
  before_save :link_to_profile_by_orcid

  # Return the display name - full_name if present, otherwise construct from given_name and family_name
  def display_name
    full_name.presence || "#{given_name} #{family_name}".strip
  end

  private

  def name_presence
    if full_name.blank? && (given_name.blank? || family_name.blank?)
      errors.add(:base, "Either full_name or both given_name and family_name must be present")
    end
  end

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
