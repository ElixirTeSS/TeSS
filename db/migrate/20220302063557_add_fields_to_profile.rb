class AddFieldsToProfile < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :fields, :string, array: true, default: []
  end
end
