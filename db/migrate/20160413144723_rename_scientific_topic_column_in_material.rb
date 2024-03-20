# frozen_string_literal: true

class RenameScientificTopicColumnInMaterial < ActiveRecord::Migration[4.2]
  def change
    rename_column :materials, :scientific_topic, :scientific_topics
  end
end
