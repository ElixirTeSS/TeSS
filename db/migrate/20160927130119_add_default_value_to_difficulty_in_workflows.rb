# frozen_string_literal: true

class AddDefaultValueToDifficultyInWorkflows < ActiveRecord::Migration[4.2]
  def change
    change_column_default :workflows, :difficulty_level, 'notspecified'
    Workflow.find_each do |wf|
      wf.update_column(:difficulty_level, 'notspecified') if wf.difficulty_level.blank?
    end
  end
end
