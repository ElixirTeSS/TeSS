class CreateScientificTopicLinks < ActiveRecord::Migration[4.2]
  def change
    create_table :scientific_topic_links do |t|
      t.references :scientific_topic, index: true, foreign_key: true
      t.references :resource, polymorphic: true, index: true
    end
  end
end
