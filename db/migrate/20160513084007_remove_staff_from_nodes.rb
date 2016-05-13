class RemoveStaffFromNodes < ActiveRecord::Migration
  def change
    remove_column :nodes, :staff, :string, array: true
  end
end
