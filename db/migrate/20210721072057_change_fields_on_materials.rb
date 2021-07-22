class ChangeFieldsOnMaterials < ActiveRecord::Migration[5.2]
  def change
    rename_column :materials, :duration, :other_types
  end
end
