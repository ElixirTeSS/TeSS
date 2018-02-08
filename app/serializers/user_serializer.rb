class UserSerializer < ApplicationSerializer
  attributes :id, :slug, :username, :firstname, :surname, :created_at, :updated_at

  def firstname
    object.profile.firstname if object.profile
  end

  def surname
    object.profile.surname if object.profile
  end
end
