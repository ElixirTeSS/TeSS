module HasPeople
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
      has_many role_name, -> { where(role: role_key) }, class_name: 'Person', as: :resource, inverse_of: :resource

      # Define custom setter that accepts strings (legacy), hashes, or Person objects
      define_method("#{role_name}=") do |value|
        super(set_people_for_role(value, role_key))
      end
    end
  end

  private

  # Set people for a specific role, accepting various input formats
  def set_people_for_role(value, role_key)
    # Remove existing links for this role
    people.where(role: role_key).destroy_all

    Array(value).reject(&:blank?).map do |person_data|
      if person_data.is_a?(String)
        # Legacy format: store as full_name directly
        people.build(full_name: person_data.strip, role: role_key)
      elsif person_data.is_a?(Hash)
        people.build(**person_data, role: role_key)
      elsif person_data.is_a?(Person)
        person_data.role = role_key
        person_data
      end
    end
  end
end
