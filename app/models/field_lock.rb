# frozen_string_literal: true

class FieldLock < ApplicationRecord
  belongs_to :resource, polymorphic: true
  validates :field, presence: true
end
