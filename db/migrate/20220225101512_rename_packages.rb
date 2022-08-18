class RenamePackages < ActiveRecord::Migration[6.1]
  def change
    rename_table :packages, :collections
    rename_table :package_events, :collection_events
    rename_table :package_materials, :collection_materials
  end
end
