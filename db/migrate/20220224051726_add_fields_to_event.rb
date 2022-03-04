class AddFieldsToEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :fields, :string, array: true, default: []
  end
end
