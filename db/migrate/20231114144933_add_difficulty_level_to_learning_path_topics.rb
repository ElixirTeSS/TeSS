class AddDifficultyLevelToLearningPathTopics < ActiveRecord::Migration[7.0]
  def change
    add_column :learning_path_topics, :difficulty_level, :string, default: 'notspecified'
  end
end
