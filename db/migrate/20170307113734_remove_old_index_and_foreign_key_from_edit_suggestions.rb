class RemoveOldIndexAndForeignKeyFromEditSuggestions < ActiveRecord::Migration[6.1]
  def up
    remove_index :edit_suggestions, :suggestible_id, if_exists: true
    if foreign_key_exists?(:edit_suggestions, column: :suggestible_id)
      remove_foreign_key :edit_suggestions, column: :suggestible_id
    end
  end

  def down
    add_index :edit_suggestions, :suggestible_id, if_not_exists: true
  end
end
