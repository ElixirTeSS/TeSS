class AddUserIdToMaterials < ActiveRecord::Migration[4.2]
  def change
    add_column :materials, :user_id, :integer
  end
end
