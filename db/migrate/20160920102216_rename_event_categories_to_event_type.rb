class RenameEventCategoriesToEventType < ActiveRecord::Migration[4.2]
  def change
    rename_column :events, :category, :event_type
  end
end
