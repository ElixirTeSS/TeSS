class CreateLearningPathTopicItems < ActiveRecord::Migration[7.0]
  def change
    create_table :learning_path_topic_items do |t|
      t.references :topic, index: true
      t.references :resource, polymorphic: true, index: true
      t.text :comment
      t.integer :order
      t.timestamps
    end
  end
end
