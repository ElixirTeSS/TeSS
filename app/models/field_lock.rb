class FieldLock < ActiveRecord::Base

  belongs_to :resource, polymorphic: true
  validates :field, inclusion: { in: -> (field_lock) { field_lock.resource.attribute_names } },
                    presence: true

end
