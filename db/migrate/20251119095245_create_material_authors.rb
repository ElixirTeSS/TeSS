class CreateMaterialAuthors < ActiveRecord::Migration[7.2]
  def change
    create_table :material_authors do |t|
      t.references :material, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: true

      t.timestamps
    end

    add_index :material_authors, [:material_id, :author_id], unique: true
  end
end
