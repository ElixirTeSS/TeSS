class AddLicenceAndDifficultyLevelToMaterials < ActiveRecord::Migration[4.2]
  def change
    add_column :materials, :licence, :string
    add_column :materials, :difficulty_level, :string
  end
end
