class RenamePackageCols < ActiveRecord::Migration[6.1]
  def change
    rename_column :collection_events, :package_id, :collection_id
    rename_column :collection_materials, :package_id, :collection_id
  end
end
