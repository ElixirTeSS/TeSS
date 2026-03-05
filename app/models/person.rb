class Person < ApplicationRecord
  include HasOrcid

  belongs_to :profile, optional: true
  belongs_to :resource, polymorphic: true

  validates :resource, :role, :name, presence: true

  # Automatically link to profile based on ORCID on save
  before_save :link_to_profile_by_orcid

  # Return the display name - currently just the full name
  def display_name
    name
  end

  # Extract person attributes from a string containing a person's name and possibly an ORCID.
  def self.attr_from_string(person_string)
    orcid = nil
    name = person_string.gsub(/\s*\(?(orcid: )?(https?:\/\/orcid\.org\/)?(\d\d\d\d-\d\d\d\d-\d\d\d\d-\d\d\d[\dxX])[ \)]*/) do |_|
      orcid = $3
      ''
    end.strip
    { name: name, orcid: orcid }
  end

  # For autocomplete
  def self.starting_with(query)
    where('lower(name) LIKE ?', "#{query.downcase}%")
  end

  def self.query(query, limit = nil)
    q = select(:name, :orcid, :profile_id).starting_with(query).distinct
    q = q.limit(limit) if limit
    q.order(name: :asc)
  end

  private

  # Automatically link to a Profile if one exists with a matching ORCID, or unlink if no match.
  def link_to_profile_by_orcid
    if orcid.blank?
      self.profile = nil
    else
      self.profile = Profile.find_by(orcid: orcid, orcid_authenticated: true)
    end
  end
end
