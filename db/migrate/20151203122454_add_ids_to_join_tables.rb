class AddIdsToJoinTables < ActiveRecord::Migration[4.2]
  def change
    add_column :package_materials, :id, :integer
    add_column :package_events, :id, :integer
  end
end
