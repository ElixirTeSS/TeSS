class DropEditSuggestionsScientificTopics < ActiveRecord::Migration
  def up
    drop_table :edit_suggestions_scientific_topics
  end

  def down
    create_table "edit_suggestions_scientific_topics", id: false do |t|
      t.integer "edit_suggestion_id"
      t.integer "scientific_topic_id"
    end
  end
end
