class AddResourceTypeToMaterials < ActiveRecord::Migration[4.2]
  def change
    add_column :materials, :resource_type, :string, array: true, default: []
  end
end
