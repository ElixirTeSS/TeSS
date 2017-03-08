class AddIndexToEditSuggestions < ActiveRecord::Migration
  def change
    add_index :edit_suggestions, [:suggestible_id, :suggestible_type]
  end
end
