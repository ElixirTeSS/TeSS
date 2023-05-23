# frozen_string_literal: true

class WidgetLog < ApplicationRecord
  belongs_to :resource, polymorphic: true
end
