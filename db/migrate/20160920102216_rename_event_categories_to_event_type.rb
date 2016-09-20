class RenameEventCategoriesToEventType < ActiveRecord::Migration
  def change
    rename_column :events, :category, :event_type
  end
end
