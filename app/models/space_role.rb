class SpaceRole < ApplicationRecord
  ROLES = ['admin'].freeze
  belongs_to :user
  belongs_to :space

  validates :key, inclusion: { in: ROLES }
end
