module HasPeople
  VALID_ATTRS = [:name, :orcid, :profile_id].freeze
  extend ActiveSupport::Concern

  class_methods do
    # Define a person role association (e.g., :authors, :contributors)
    # This creates the association and a custom setter that accepts strings, hashes, or Person objects
    def has_person_role(role_name)
      role_key = role_name.to_s.singularize
      # Define the association
      has_many role_name, -> { where(role: role_key) }, class_name: 'Person', as: :resource, inverse_of: :resource,
               autosave: true, dependent: :destroy

      # Define custom setter that accepts strings (legacy), hashes, or Person objects
      define_method("#{role_name}=") do |value|
        super(set_people_for_role(value, role_name, role_key))
      end
    end
  end

  private

  # Set people for a specific role, accepting various input formats
  def set_people_for_role(value, role_name, role_key)
    send(role_name).reset
    current_people = send(role_name).to_a
    to_keep = []

    Array(value).reject(&:blank?).map do |person_data|
      person_data = person_data.to_h if person_data.is_a?(ActionController::Parameters)
      if person_data.is_a?(String)
        attrs = { name: person_data.strip }
      elsif person_data.is_a?(Hash)
        attrs = person_data.with_indifferent_access.slice(*VALID_ATTRS)
      elsif person_data.is_a?(Person)
        attrs = person_data.attributes.with_indifferent_access.slice(*VALID_ATTRS)
      end

      idx = current_people.index { |p| (p.orcid.present? && p.orcid == attrs[:orcid]) || p.name == attrs[:name] }
      if idx
        match = current_people.delete_at(idx)
        match.assign_attributes(**attrs, role: role_key)
        to_keep << match
      else
        if person_data.is_a?(Person)
          person = person_data
          person.role = role_key
        else
          person = send(role_name).build(**attrs)
        end
        to_keep << person
      end
    end

    current_people.each(&:mark_for_destruction) # Now contains only redundant records

    to_keep
  end
end
