class AddSuggestionRefToMaterial < ActiveRecord::Migration
  def change
    add_reference :edit_suggestions, :material, index: true, foreign_key: true
  end
end
