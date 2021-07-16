class UpdateDetailsOfMaterials < ActiveRecord::Migration[5.2]
  def change
    add_column :materials, :contact, :text
    remove_column :materials, :short_description
  end
end
