# frozen_string_literal: true

class UserSerializer < ApplicationSerializer
  attributes :id, :slug, :username, :firstname, :surname, :created_at, :updated_at

  def firstname
    object.profile&.firstname
  end

  def surname
    object.profile&.surname
  end
end
