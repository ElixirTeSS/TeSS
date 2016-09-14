class NodeLink < ActiveRecord::Base

  belongs_to :node
  belongs_to :resource, polymorphic: true

end
