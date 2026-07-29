class AddLanguagesToMaterials < ActiveRecord::Migration[8.1]
  def change
    add_column :materials, :language, :string, array: true, default: []
  end
end
