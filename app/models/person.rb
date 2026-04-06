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

  # For autocomplete
  def self.starting_with(query)
    where('lower(name) LIKE ?', "#{query.downcase}%")
  end

  def self.query(query, limit = nil)
    q = select(:name, :orcid, :profile_id).starting_with(query).distinct
    q = q.limit(limit) if limit
    q.order(name: :asc, orcid: :asc)
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
