# frozen_string_literal: true

class NodeLink < ApplicationRecord
  belongs_to :node
  belongs_to :resource, polymorphic: true
end
