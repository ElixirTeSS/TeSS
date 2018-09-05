class RenameEventTypeToEventTypes < ActiveRecord::Migration[4.2]
  def change
    rename_column :events, :event_type, :event_types
  end
end
