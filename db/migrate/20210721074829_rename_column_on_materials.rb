class RenameColumnOnMaterials < ActiveRecord::Migration[5.2]
  def change
    rename_column :materials, :description, :description
  end
end
