class CreateJoinTableGroupsUsers < ActiveRecord::Migration[7.2]
  def change
    create_join_table :groups, :users do |t|
      # t.index [:group_id, :user_id]
      # t.index [:user_id, :group_id]
    end
  end
end
