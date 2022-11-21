class CreateCollectionItems < ActiveRecord::Migration[6.1]
  def change
    create_table :collection_items do |t|
      t.references :collection, index: true
      t.references :resource, polymorphic: true, index: true
      t.text :comment
      t.integer :order
      t.timestamps
    end
  end
end
