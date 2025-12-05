class PersonSerializer < ApplicationSerializer
  attributes :id, :given_name, :family_name, :full_name, :orcid, :profile_id

  # Return display_name for API responses
  attribute :name do |person|
    person.display_name
  end
end
