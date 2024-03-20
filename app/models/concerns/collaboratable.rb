# frozen_string_literal: true

module Collaboratable
  extend ActiveSupport::Concern

  included do
    has_many :collaborations, as: :resource, dependent: :destroy
    has_many :collaborators, through: :collaborations, source: :user
  end

  def collaborator?(user)
    collaborators.include?(user)
  end
end
