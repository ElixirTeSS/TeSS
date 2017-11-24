class WorkflowSerializer < ApplicationSerializer
  attributes :id, :slug, :title, :description, :workflow_content,
             :keywords, :contributors, :authors, :target_audience,
             :licence, :difficulty_level, :scientific_topics,
             :created_at, :updated_at

  belongs_to :user
end
