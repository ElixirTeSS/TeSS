class Person < ApplicationRecord
  has_many :person_links, dependent: :destroy

  # Validate that at least a full_name OR both given_name and family_name are present
  validate :name_presence

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
end
