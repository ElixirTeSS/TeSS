class RemoveAuthorsFromMaterials < ActiveRecord::Migration[7.2]
  def change
    remove_column :materials, :authors, :string, array: true, default: []
    remove_column :materials, :contributors, :string, array: true, default: []
  end
end
