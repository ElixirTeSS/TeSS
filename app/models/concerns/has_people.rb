module HasPeople
  VALID_ATTRS = [:full_name, :orcid, :profile_id].freeze
  extend ActiveSupport::Concern

  included do
    has_many :people, as: :resource, dependent: :destroy, inverse_of: :resource
    accepts_nested_attributes_for :people, allow_destroy: true, reject_if: :all_blank
  end

  class_methods do
    # Define a person role association (e.g., :authors, :contributors)
    # This creates the association and a custom setter that accepts strings, hashes, or Person objects
    def has_person_role(role_name, role_key: role_name.to_s.singularize)
      # Define the association
      has_many role_name, -> { where(role: role_key) }, class_name: 'Person', as: :resource, inverse_of: :resource,
               autosave: true, dependent: :destroy

      # Define custom setter that accepts strings (legacy), hashes, or Person objects
      define_method("#{role_name}=") do |value|
        super(set_people_for_role(value, role_key))
      end
    end
  end

  private

  # Set people for a specific role, accepting various input formats
  def set_people_for_role(value, role_key)
    current_people = people.where(role: role_key).to_a
    to_keep = []

    Array(value).reject(&:blank?).map do |person_data|
      if person_data.is_a?(String)
        attrs = { full_name: person_data.strip }
      elsif person_data.is_a?(Hash)
        attrs = person_data.with_indifferent_access.slice(*VALID_ATTRS)
      elsif person_data.is_a?(Person)
        attrs = person_data.attributes.with_indifferent_access.slice(*VALID_ATTRS)
      end

      idx = current_people.index { |p| p.orcid == attrs[:orcid] || p.full_name == attrs[:full_name] }
      if idx
        match = current_people.delete_at(idx)
        match.assign_attributes(**attrs, role: role_key)
        to_keep << match
      else
        to_keep << people.build(**attrs, role: role_key)
      end
    end

    current_people.each(&:mark_for_destruction) # Now contains only redundant records

    to_keep
  end
end
