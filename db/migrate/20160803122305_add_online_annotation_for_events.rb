class AddOnlineAnnotationForEvents < ActiveRecord::Migration[4.2]
  def up
    add_column :events, :online, :boolean, :default => false
    add_index :events, :online
  end

  def down
    remove_index :events, :online
    remove_column :events, :online
  end
end
