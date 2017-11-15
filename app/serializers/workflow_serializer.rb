class WorkflowSerializer < ApplicationSerializer
  attributes :id, :title, :description, :workflow_content,
             :keywords, :contributors, :authors, :target_audience, :scientific_topics,
             :created_at, :updated_at

  belongs_to :user
end
