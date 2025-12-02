class CreatePeople < ActiveRecord::Migration[7.2]
  def change
    create_table :people do |t|
      t.string :first_name
      t.string :last_name
      t.string :orcid

      t.timestamps
    end

    add_index :people, :orcid
  end
end
