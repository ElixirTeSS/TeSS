class Star < ApplicationRecord

  belongs_to :user
  belongs_to :resource, polymorphic: true

  validates :resource_id, presence: true, uniqueness: { scope: [:resource_type, :user_id] }

end
