# A Group is a collection of users, joined via GroupMembership.
#
# Groups are primarily used to control access to private Space objects: a
# private space is only accessible to users belonging to one of the space's
# associated groups (see ApplicationPolicy#shown?).
class Group < ApplicationRecord
  # The individual user memberships (with owner status) belonging to this
  # group. Destroyed along with the group.
  has_many :group_memberships, dependent: :destroy

  # The users belonging to this group, through #group_memberships.
  has_many :users, through: :group_memberships

  # The spaces this group grants access to.
  has_and_belongs_to_many :spaces
end