class FieldLock < ActiveRecord::Base

  belongs_to :resource, polymorphic: true
  validates :field, presence: true

end
