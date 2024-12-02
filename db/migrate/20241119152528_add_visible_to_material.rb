class AddVisibleToMaterial < ActiveRecord::Migration[7.0]
  def change
    add_column :materials, :visible, :bool, default: true
  end
end
