class AddUserIdToMaterials < ActiveRecord::Migration
  def change
    add_column :materials, :user_id, :integer
  end
end
