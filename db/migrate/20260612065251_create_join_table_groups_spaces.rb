class CreateJoinTableGroupsSpaces < ActiveRecord::Migration[7.2]
  def change
    create_join_table :groups, :spaces do |t|
      # t.index [:group_id, :space_id]
      # t.index [:space_id, :group_id]
    end
  end
end
