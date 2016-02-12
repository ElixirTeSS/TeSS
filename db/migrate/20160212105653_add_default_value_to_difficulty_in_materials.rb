class AddDefaultValueToDifficultyInMaterials < ActiveRecord::Migration
  def change
    change_column_default :materials, :difficulty_level, 'notspecified'
    Material.find_each do |material|
      if material.difficulty_level.blank?
        material.difficulty_level = 'notspecified'
        material.save!
      end
    end
  end
end
