class AddNameToEditSuggestion < ActiveRecord::Migration
  def change
    add_column :edit_suggestions, :name, :text
  end
end
