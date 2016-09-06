class Workflow < ActiveRecord::Base

  include PublicActivity::Common
  include HasScientificTopics
  include Collaboratable

  has_paper_trail

  extend FriendlyId
  friendly_id :title, use: :slugged

  if SOLR_ENABLED
    searchable do
      string :title
      string :description
      text :title
      text :description
    end
  end

  # has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user

  validates :title, presence: true

  clean_array_fields(:keywords, :contributors, :authors, :target_audience)

  update_suggestions(:keywords, :contributors, :authors, :target_audience)

  after_save :log_diagram_modification

  def self.facet_fields
    %w( )
  end

  private

  def log_diagram_modification
    old_nodes = workflow_content_was['nodes']
    old_node_ids = old_nodes.map { |n| n['data']['id'] }
    current_nodes = workflow_content['nodes']
    current_node_ids = current_nodes.map { |n| n['data']['id'] }

    added_node_ids = (current_node_ids - old_node_ids)
    removed_node_ids =  (old_node_ids - current_node_ids)
    modified_node_ids = (current_nodes - old_nodes).map { |n| n['data']['id'] } - added_node_ids

    # Resolve the actual nodes from the IDs
    added_nodes = added_node_ids.map { |i| workflow_content['nodes'].detect { |n| n['data']['id'] == i } }
    removed_nodes = removed_node_ids.map { |i| workflow_content_was['nodes'].detect { |n| n['data']['id'] == i } }
    modified_nodes = modified_node_ids.map { |i| workflow_content['nodes'].detect { |n| n['data']['id'] == i } }

    if added_node_ids.any? || removed_node_ids.any? || modified_node_ids.any?
      self.create_activity :modify_diagram, parameters: {
          added_nodes: added_nodes,
          removed_nodes: removed_nodes,
          modified_nodes: modified_nodes
      }
    end
  end


end
