class MakeExternalResourcesPolymorphic < ActiveRecord::Migration[4.2]
  def up
    remove_foreign_key :external_resources, :materials

    remove_index :external_resources, [:material_id]

    rename_column :external_resources, :material_id, :source_id

    add_column :external_resources, :source_type, :string

    ExternalResource.connection.execute("UPDATE external_resources SET source_type = 'Material'")

    add_index :external_resources, [:source_id, :source_type]
  end

  def down
    remove_index :external_resources, [:source_id, :source_type]

    rename_column :external_resources, :source_id, :material_id

    remove_column :external_resources, :source_type

    add_index :external_resources, [:material_id]

    add_foreign_key :external_resources, :materials
  end
end
