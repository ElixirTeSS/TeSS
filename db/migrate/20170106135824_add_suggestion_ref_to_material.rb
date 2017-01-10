class AddSuggestionRefToMaterial < ActiveRecord::Migration
  def change
    add_reference :edit_suggestion, :material, index: true, foreign_key: true
  end
end
