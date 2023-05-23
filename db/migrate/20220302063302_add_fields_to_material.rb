# frozen_string_literal: true

class AddFieldsToMaterial < ActiveRecord::Migration[5.2]
  def change
    add_column :materials, :fields, :string, array: true, default: []
  end
end
