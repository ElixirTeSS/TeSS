# frozen_string_literal: true

class AddFieldsToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :username, :string
    add_index :users, :username, unique: true
  end
end
