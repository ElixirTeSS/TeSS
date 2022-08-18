class RemoveMaterialIdFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :material_id, :integer
  end
end
