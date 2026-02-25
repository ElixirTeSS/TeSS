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

  # Extract person attributes from a string containing a person's name and possibly an ORCID.
  def self.attr_from_string(person_string)
    orcid = nil
    name = person_string.gsub(/\s*\(?(orcid: )?(https?:\/\/orcid\.org\/)?(\d\d\d\d-\d\d\d\d-\d\d\d\d-\d\d\d[\dxX])[ \)]*/) do |_|
      orcid = $3
      ''
    end.strip
    { full_name: name, orcid: orcid }
  end

  private

  # Automatically link to a Profile if one exists with a matching ORCID
  def link_to_profile_by_orcid
    if orcid.blank?
      self.profile = nil
    else
      matching_profile = Profile.find_by(orcid: orcid, orcid_authenticated: true)
      self.profile = matching_profile if matching_profile.present?
    end
  end
end
