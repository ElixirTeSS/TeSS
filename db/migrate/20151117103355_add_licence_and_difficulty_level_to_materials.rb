class AddLicenceAndDifficultyLevelToMaterials < ActiveRecord::Migration
  def change
    add_column :materials, :licence, :string
    add_column :materials, :difficulty_level, :string
  end
end
