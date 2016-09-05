class Collaboration < ActiveRecord::Base

  belongs_to :user
  belongs_to :resource, polymorphic: true

  validates_uniqueness_of :user, scope: :resource, message: 'is already a collaborator'

end
