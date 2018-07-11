json.extract! @workflow, :id, :title, :description, :user_id, :workflow_content, :created_at, :updated_at

json.partial! 'common/ontology_terms', type: 'scientific_topics', resource: @workflow
