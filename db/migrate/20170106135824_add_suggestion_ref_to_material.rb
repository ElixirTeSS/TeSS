class AddSuggestionRefToMaterial < ActiveRecord::Migration
  def change
    add_reference :materials, :edit_suggestion, index: true, foreign_key: true
  end
end
