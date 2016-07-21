class CreateExternalResources < ActiveRecord::Migration
  def change
    create_table :external_resources do |t|
      t.references :material, index: true, foreign_key: true
      t.text :url
      t.string :title

      t.timestamps null: false
    end
  end
end
