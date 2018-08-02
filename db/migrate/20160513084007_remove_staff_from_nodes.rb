class RemoveStaffFromNodes < ActiveRecord::Migration[4.2]
  def change
    remove_column :nodes, :staff, :string, array: true
  end
end
