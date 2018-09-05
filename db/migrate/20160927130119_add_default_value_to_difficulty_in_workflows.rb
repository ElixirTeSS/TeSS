class AddDefaultValueToDifficultyInWorkflows < ActiveRecord::Migration[4.2]
  def change
    change_column_default :workflows, :difficulty_level, 'notspecified'
    Workflow.find_each do |wf|
      if wf.difficulty_level.blank?
        wf.update_column(:difficulty_level, 'notspecified')
      end
    end
  end
end
