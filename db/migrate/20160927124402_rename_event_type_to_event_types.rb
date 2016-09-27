class RenameEventTypeToEventTypes < ActiveRecord::Migration
  def change
    rename_column :events, :event_type, :event_types
  end
end
