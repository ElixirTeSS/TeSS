module HasPeople
  extend ActiveSupport::Concern

  included do
    has_many :person_links, as: :resource, dependent: :destroy
    has_many :people, through: :person_links
    accepts_nested_attributes_for :person_links, allow_destroy: true, reject_if: :all_blank
  end

  class_methods do
    # Define a person role association (e.g., :authors, :contributors)
    # This creates the association and a custom setter that accepts strings, hashes, or Person objects
    def has_person_role(role_name, role_key: role_name.to_s.singularize)
      # Define the association
      has_many role_name, -> { where(person_links: { role: role_key }) }, through: :person_links, source: :person

      # Define custom setter that accepts strings (legacy), hashes, or Person objects
      define_method("#{role_name}=") do |value|
        set_people_for_role(value, role_key)
      end
    end
  end

  private

  # Set people for a specific role, accepting various input formats
  def set_people_for_role(value, role)
    return if value.nil?

    # Convert to array if needed
    people_array = Array(value).reject(&:blank?)

    # Remove existing links for this role
    person_links.where(role: role).destroy_all

    people_array.each do |person_data|
      if person_data.is_a?(String)
        # Legacy format: store as full_name directly
        person = Person.find_or_create_by!(full_name: person_data.strip)
        person_links.build(person: person, role: role)
      elsif person_data.is_a?(Hash)
        # Hash format from API - supports both legacy (first_name/last_name) and new (given_name/family_name) field names
        given_name = person_data[:given_name] || person_data['given_name'] || person_data[:first_name] || person_data['first_name']
        family_name = person_data[:family_name] || person_data['family_name'] || person_data[:last_name] || person_data['last_name']
        full_name = person_data[:full_name] || person_data['full_name']
        orcid = person_data[:orcid] || person_data['orcid']

        # Prefer full_name if provided, otherwise use given_name and family_name
        if full_name.present?
          person = Person.find_or_create_by!(full_name: full_name)
        elsif given_name.present? && family_name.present?
          person = Person.find_or_create_by!(given_name: given_name, family_name: family_name)
        elsif given_name.present? || family_name.present?
          # If only one part is provided, treat it as full_name
          person = Person.find_or_create_by!(full_name: "#{given_name}#{family_name}".strip)
        else
          next # Skip if no name data provided
        end

        person.update!(orcid: orcid) if orcid.present?
        person_links.build(person: person, role: role)
      elsif person_data.is_a?(Person)
        # Person object
        person_links.build(person: person_data, role: role)
      end
    end
  end
end
