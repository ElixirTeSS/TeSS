class CreatePeople < ActiveRecord::Migration[7.2]
  def change
    create_table :people do |t|
      t.string :given_name
      t.string :family_name
      t.string :full_name
      t.string :orcid
      t.string :role, null: false
      t.references :resource, polymorphic: true, null: false
      t.references :profile, null: true, foreign_key: true

      t.timestamps
    end

    add_index :people, :orcid
    add_index :people, [:resource_type, :resource_id, :role]
  end
end
