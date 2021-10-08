class CreateContentProvidersUsersJoinTable < ActiveRecord::Migration[5.2]
  def down
    drop_table(:content_providers_users, if_exists: true)
  end

  def up
    create_table :content_providers_users, id: false do |t|
      t.belongs_to :content_provider, index: true
      t.belongs_to :user, index: true
    end

    add_index :content_providers_users, [:content_provider_id, :user_id], unique: true, name: :provider_user_unique
  end

end
