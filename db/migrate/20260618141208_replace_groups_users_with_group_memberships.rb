class ReplaceGroupsUsersWithGroupMemberships < ActiveRecord::Migration[7.2]
  def change
    drop_table :groups_users

    create_table :group_memberships, id: false do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.boolean :owner, default: false, null: false
      t.timestamps
    end
    
    add_index :group_memberships, [:user_id, :group_id], primary: true
  end
end
