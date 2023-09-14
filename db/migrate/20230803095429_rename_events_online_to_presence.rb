class RenameEventsOnlineToPresence < ActiveRecord::Migration[6.1]
  def change
    rename_column :events, :online, :presence
  end
end
