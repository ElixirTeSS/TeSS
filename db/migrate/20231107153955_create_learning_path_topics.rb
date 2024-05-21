class CreateLearningPathTopics < ActiveRecord::Migration[7.0]
  def change
    create_table :learning_path_topics do |t|
      t.string :title
      t.text :description
      t.integer :user_id
      t.string :keywords, default: [], array: true
      t.timestamps
    end
  end
end
