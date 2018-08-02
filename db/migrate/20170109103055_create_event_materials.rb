class CreateEventMaterials < ActiveRecord::Migration[4.2]
  def change
    create_table :event_materials do |t|
      t.references :event, index: true, foreign_key: true
      t.references :material, index: true, foreign_key: true
    end
  end
end
