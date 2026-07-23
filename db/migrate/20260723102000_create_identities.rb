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

      dir.down do
        execute <<~SQL
          UPDATE users
          SET provider = source.provider,
              uid = source.uid
          FROM (
            SELECT DISTINCT ON (user_id) user_id, provider, uid
            FROM identities
            ORDER BY user_id, created_at ASC, id ASC
          ) AS source
          WHERE users.id = source.user_id
            AND (users.provider IS NULL OR users.provider = '')
        SQL
      end
    end
  end
end
