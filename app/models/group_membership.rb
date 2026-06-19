class GroupMembership < ApplicationRecord
  self.primary_key = [:group_id, :user_id]
  belongs_to :user
  belongs_to :group
end