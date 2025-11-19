class CreateAuthors < ActiveRecord::Migration[7.2]
  def change
    create_table :authors do |t|
      t.string :first_name
      t.string :last_name
      t.string :orcid

      t.timestamps
    end

    add_index :authors, :orcid
  end
end
