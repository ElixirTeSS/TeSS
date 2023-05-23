# frozen_string_literal: true

class CreateEditSuggestions < ActiveRecord::Migration[4.2]
  def change
    create_table :edit_suggestions do |t|
      t.text :name, :text
      t.timestamps null: false
    end
  end
end
