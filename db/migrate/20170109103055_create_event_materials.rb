class CreateEventMaterials < ActiveRecord::Migration
  def change
    create_table :event_materials do |t|
      t.references :event, index: true, foreign_key: true
      t.references :material, index: true, foreign_key: true
    end
  end
end
