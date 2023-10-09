class CreateLearningPathsTopics < ActiveRecord::Migration[7.0]
  def change
    create_table :learning_paths_topics do |t|
      t.references :learning_path, index: true, foreign_key: true
      t.references :topic, index: true
      t.integer :order
      t.timestamps
    end
  end
end
