class RenameScientificTopicInWorkflows < ActiveRecord::Migration[4.2]
  def change
    rename_column :workflows, :scientific_topic, :scientific_topics
  end
end
