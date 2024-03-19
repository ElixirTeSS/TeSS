class AddCurationToEvent < ActiveRecord::Migration[7.0]
  def up
    add_column :events, :curation_show, :bool, default: true
  end

  def down
    remove_column :events, :curation_show, :bool, default: true
  end
end
