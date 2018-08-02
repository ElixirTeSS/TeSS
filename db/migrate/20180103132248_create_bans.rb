class CreateBans < ActiveRecord::Migration[4.2]
  def change
    create_table :bans do |t|
      t.references :user, index: true
      t.references :banner, references: :users, index: true
      t.boolean :shadow
      t.text :reason

      t.timestamps null: false
    end

    add_foreign_key :bans, :users, column: :user_id
    add_foreign_key :bans, :users, column: :banner_id
  end
end
