class MakeEditSuggestionPolymorphic < ActiveRecord::Migration
  def change
    add_reference :materials, :suggestible, polymorphic: true
    add_reference :events, :suggestible, polymorphic: true
    add_reference :workflows, :suggestible, polymorphic: true
    add_column :edit_suggestions, :suggestible_type, :string
    add_column :edit_suggestions, :suggestible_id, :integer
    remove_column :edit_suggestions, :material_id, :integer
  end
end
