class AddMaterialIdToEditSuggestion < ActiveRecord::Migration
  def change
    add_column :edit_suggestions, :material_id, :integer
  end
end
