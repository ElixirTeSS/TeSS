class RenamePackageEvents < ActiveRecord::Migration[6.1]
  def change
    rename_table :collection_events, :collection_events
  end
end
