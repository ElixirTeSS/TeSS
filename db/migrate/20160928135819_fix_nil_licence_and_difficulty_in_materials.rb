class FixNilLicenceAndDifficultyInMaterials < ActiveRecord::Migration
  def change
    Material.transaction do
      Material.find_each do |m|
        m.update_column(:licence, 'notspecified') if m.licence.blank?
        m.update_column(:difficulty_level, 'notspecified') if m.difficulty_level.blank?
      end
    end
  end
end
