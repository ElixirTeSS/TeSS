class AddIdentityUrlToUsers < ActiveRecord::Migration
  def change
    add_column :users, :identity_url, :string
    add_index :users, :identity_url, :unique => true
  end
end
