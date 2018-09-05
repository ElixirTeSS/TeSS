class RemoveOldIndexAndForeignKeyFromEditSuggestions < ActiveRecord::Migration[4.2]
  def change
    remove_index :edit_suggestions, :suggestible_id
    remove_foreign_key :edit_suggestions, column: :suggestible_id
  end
end
