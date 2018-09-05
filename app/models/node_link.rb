class NodeLink < ApplicationRecord

  belongs_to :node
  belongs_to :resource, polymorphic: true

end
