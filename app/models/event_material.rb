class EventMaterial < ActiveRecord::Base

  belongs_to :event
  belongs_to :material

end
