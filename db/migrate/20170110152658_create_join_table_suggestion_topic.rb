class CreateJoinTableSuggestionTopic < ActiveRecord::Migration
  def change
    create_table :edit_suggestions_scientific_topics, id: false do |t|
      t.integer :edit_suggestion_id
      t.integer :scientific_topic_id
    end
  end
end
