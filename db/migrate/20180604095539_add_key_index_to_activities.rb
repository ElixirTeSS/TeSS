# frozen_string_literal: true

class AddKeyIndexToActivities < ActiveRecord::Migration[4.2]
  def change
    add_index :activities, :key
  end
end
