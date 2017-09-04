class Star < ActiveRecord::Base

  belongs_to :user
  belongs_to :resource, polymorphic: true

  validates :resource, presence: true

end
