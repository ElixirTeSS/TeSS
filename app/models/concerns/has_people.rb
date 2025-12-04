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
        # Legacy format: parse string into first_name and last_name
        parts = person_data.strip.split(/\s+/, 2)
        first_name = parts.length > 1 ? parts[0] : ''
        last_name = parts.length > 1 ? parts[1] : parts[0]

        person = Person.find_or_create_by!(first_name: first_name, last_name: last_name)
        person_links.build(person: person, role: role)
      elsif person_data.is_a?(Hash)
        # Hash format from API
        first_name = person_data[:first_name] || person_data['first_name'] || ''
        last_name = person_data[:last_name] || person_data['last_name'] || ''
        orcid = person_data[:orcid] || person_data['orcid']

        person = Person.find_or_create_by!(first_name: first_name, last_name: last_name)
        person.update!(orcid: orcid) if orcid.present?
        person_links.build(person: person, role: role)
      elsif person_data.is_a?(Person)
        # Person object
        person_links.build(person: person_data, role: role)
      end
    end
  end
end
