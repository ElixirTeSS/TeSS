class RenameScientificTopicInWorkflows < ActiveRecord::Migration
  def change
    rename_column :workflows, :scientific_topic, :scientific_topics
  end
end
