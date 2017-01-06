class AddSuggestionRefToScientificTopic < ActiveRecord::Migration
  def change
    add_reference :scientific_topics, :edit_suggestion, index: true, foreign_key: true
  end
end
