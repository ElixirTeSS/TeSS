class StaffMember < ActiveRecord::Base
  belongs_to :node

  validates :name, presence: true

  scope :training_coordinators, -> { where(role: 'Training coordinator') }
end
