# frozen_string_literal: true

class AddDescriptionToNodes < ActiveRecord::Migration[4.2]
  def change
    add_column :nodes, :description, :text
  end
end
