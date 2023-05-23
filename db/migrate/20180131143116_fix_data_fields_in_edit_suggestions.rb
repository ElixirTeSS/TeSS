# frozen_string_literal: true

class FixDataFieldsInEditSuggestions < ActiveRecord::Migration[4.2]
  class EditSuggestion < ApplicationRecord
  end

  def up
    EditSuggestion.where(data_fields: nil).update_all(data_fields: {})
  end

  def down; end
end
