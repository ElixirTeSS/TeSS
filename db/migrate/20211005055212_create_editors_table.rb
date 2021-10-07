class CreateEditorsTable < ActiveRecord::Migration[5.2]
  def down
    drop_table(:editors, if_exists: true)
  end

  def up
    create_table :editors, id: false do |t|
      t.references :content_provider, foreign_key: true
      t.references :user, foreign_key: true
    end

    add_index :editors, [:content_provider_id, :user_id], unique: true

  end

end
