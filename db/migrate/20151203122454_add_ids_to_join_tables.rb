class AddIdsToJoinTables < ActiveRecord::Migration
  def change
    add_column :package_materials, :id, :integer
    add_column :package_events, :id, :integer
  end
end
