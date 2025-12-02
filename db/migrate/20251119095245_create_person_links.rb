class CreatePersonLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :person_links do |t|
      t.references :resource, polymorphic: true, null: false
      t.references :person, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end

    add_index :person_links, [:resource_type, :resource_id, :person_id, :role],
              unique: true, name: 'index_person_links_uniqueness'
  end
end
