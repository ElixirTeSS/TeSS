# GroupMembership is the join model between User and Group.
#
# Beyond simple membership, it also tracks whether the user is an *owner*
# of the group (see the +owner+ attribute, managed for example by
# GroupsController#sync_owners), which grants additional permissions such
# as editing or destroying the group (see GroupPolicy#owner?).
class GroupMembership < ApplicationRecord
  # Composite primary key: a user can only have a single membership per
  # group.
  self.primary_key = [:group_id, :user_id]

  belongs_to :user
  belongs_to :group
end