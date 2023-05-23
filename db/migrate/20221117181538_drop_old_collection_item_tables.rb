# frozen_string_literal: true

class DropOldCollectionItemTables < ActiveRecord::Migration[6.1]
  def change
    drop_table :collection_events do |t|
      t.references :event
      t.references :collection
      t.timestamps
    end

    drop_table :collection_materials do |t|
      t.references :material
      t.references :collection
      t.timestamps
    end
  end
end
