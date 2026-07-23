class CreateIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid

      t.timestamps
    end

    add_index :identities, [:provider, :uid], unique: true

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO identities (user_id, provider, uid, created_at, updated_at)
          SELECT id, provider, uid, NOW(), NOW()
          FROM users
          WHERE provider IS NOT NULL AND provider <> ''
          ON CONFLICT (provider, uid) DO NOTHING
        SQL
      end
    end
  end
end
