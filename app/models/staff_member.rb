class StaffMember < ActiveRecord::Base
  belongs_to :node

  validates :name, presence: true
end
