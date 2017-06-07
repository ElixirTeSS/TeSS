class AddResourceTypeToMaterials < ActiveRecord::Migration
  def change
    add_column :materials, :resource_type, :text
  end
end
