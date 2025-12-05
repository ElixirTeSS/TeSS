class Person < ApplicationRecord
  belongs_to :profile, optional: true
  has_many :person_links, dependent: :destroy

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
    return if orcid.blank?
    return if profile_id.present? # Already linked

    # Normalize the ORCID for matching - Profile stores it as a full URL
    normalized_orcid = orcid.strip
    if normalized_orcid =~ OrcidValidator::ORCID_ID_REGEX
      normalized_orcid = "#{OrcidValidator::ORCID_PREFIX}#{normalized_orcid}"
    end

    matching_profile = Profile.find_by(orcid: normalized_orcid)
    self.profile = matching_profile if matching_profile.present?
  end
end
