class MakeEditSuggestionPolymorphic < ActiveRecord::Migration[4.2]
  def up
    add_reference :materials, :suggestible, polymorphic: true
    add_reference :events, :suggestible, polymorphic: true
    add_reference :workflows, :suggestible, polymorphic: true
    add_column :edit_suggestions, :suggestible_type, :string
    rename_column :edit_suggestions, :material_id, :suggestible_id
    EditSuggestion.connection.execute("UPDATE edit_suggestions SET suggestible_type = 'Material'")
  end

  def down
    remove_reference :materials, :suggestible, polymorphic: true
    remove_reference :events, :suggestible, polymorphic: true
    remove_reference :workflows, :suggestible, polymorphic: true
    remove_column :edit_suggestions, :suggestible_type, :string
    rename_column :edit_suggestions, :suggestible_id, :material_id
  end
end
