class AddIndexToEditSuggestions < ActiveRecord::Migration[4.2]
  def change
    add_index :edit_suggestions, [:suggestible_id, :suggestible_type]
  end
end
