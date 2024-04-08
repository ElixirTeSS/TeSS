class AddCurationToEvent < ActiveRecord::Migration[7.0]
  def up
    add_column :events, :visible, :bool, default: true
  end

  def down
    remove_column :events, :visible, :bool
  end
end
