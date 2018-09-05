class AddMultipleAuthorsContributorsToMaterials < ActiveRecord::Migration[4.2]
  def change
    add_column :materials, :authors, :string, array: true, default: []
    add_column :materials, :contributors, :string, array: true, default: []
  end
end
