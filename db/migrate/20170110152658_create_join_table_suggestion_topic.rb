class CreateJoinTableSuggestionTopic < ActiveRecord::Migration[4.2]
  def change
    create_table :edit_suggestions_scientific_topics, id: false do |t|
      t.integer :edit_suggestion_id
      t.integer :scientific_topic_id
    end
  end
end
