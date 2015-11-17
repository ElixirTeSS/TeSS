class AddMultipleAuthorsContributorsToMaterials < ActiveRecord::Migration
  def change
    add_column :materials, :authors, :string, array: true, default: []
    add_column :materials, :contributors, :string, array: true, default: []
  end
end
