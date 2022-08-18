class AddIdentityUrlToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :identity_url, :string
    add_index :users, :identity_url, :unique => true
  end
end
