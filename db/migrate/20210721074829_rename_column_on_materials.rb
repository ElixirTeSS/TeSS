class RenameColumnOnMaterials < ActiveRecord::Migration[5.2]
  def change
    rename_column :materials, :long_description, :description
  end
end
