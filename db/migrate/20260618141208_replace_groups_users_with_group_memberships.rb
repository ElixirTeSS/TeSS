class ReplaceGroupsUsersWithGroupMemberships < ActiveRecord::Migration[7.2]
  def change
    drop_table :groups_users

    create_table :group_memberships, id: false, primary_key: [:group_id, :user_id] do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.boolean :owner, default: false, null: false
      t.timestamps
    end
  end
end
