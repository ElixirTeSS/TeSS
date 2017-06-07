class AddResourceTypeToMaterials < ActiveRecord::Migration
  def change
    add_column :materials, :resource_type, :string, array: true, default: []
  end
end
