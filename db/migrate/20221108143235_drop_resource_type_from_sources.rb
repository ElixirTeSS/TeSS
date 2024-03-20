# frozen_string_literal: true

class DropResourceTypeFromSources < ActiveRecord::Migration[6.1]
  def change
    remove_column :sources, :resource_type, :string
  end
end
