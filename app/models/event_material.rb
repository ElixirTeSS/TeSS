# frozen_string_literal: true

class EventMaterial < ApplicationRecord
  belongs_to :event
  belongs_to :material
end
