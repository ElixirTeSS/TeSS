class AddSuggestionRefToMaterial < ActiveRecord::Migration[4.2]
  def change
    add_reference :edit_suggestions, :material, index: true, foreign_key: true
  end
end
