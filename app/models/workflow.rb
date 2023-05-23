# frozen_string_literal: true

class Workflow < ApplicationRecord
  include PublicActivity::Common
  include Collaboratable
  include LogParameterChanges
  include HasLicence
  include Searchable
  include HasSuggestions
  include IdentifiersDotOrg
  include HasFriendlyId
  include CurationQueue
  include HasDifficultyLevel

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      string :title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      string :description
      text :title
      text :description
      text :node_names do
        node_index('name')
      end
      text :node_descriptions do
        node_index('description')
      end
      text :authors
      string :authors, multiple: true
      string :scientific_topics, multiple: true do
        scientific_topic_names
      end
      text :target_audience
      string :target_audience, multiple: true
      text :keywords
      string :keywords, multiple: true
      text :contributors
      string :contributors, multiple: true

      integer :user_id
      boolean :public
      integer :collaborator_ids, multiple: true
      time :updated_at
      time :created_at
    end
    # :nocov:
  end

  # has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user

  has_ontology_terms(:scientific_topics, branch: OBO_EDAM.topics)

  has_many :stars,  as: :resource, dependent: :destroy

  validates :title, presence: true

  clean_array_fields(:keywords, :contributors, :authors, :target_audience)

  update_suggestions(:keywords, :contributors, :authors, :target_audience)

  after_update :log_diagram_modification

  def self.facet_fields
    %w[scientific_topics target_audience keywords licence difficulty_level authors contributors]
  end

  def new_fork(user)
    dup.tap do |wf|
      wf.title = "Fork of #{wf.title}"
      wf.user = user
    end
  end

  def workflow_content=(content)
    super(content.is_a?(String) ? JSON.parse(content) : content)
  end

  private

  def log_diagram_modification
    if saved_change_to_workflow_content?
      old_nodes = workflow_content_before_last_save['nodes'] || []
      old_node_ids = old_nodes.map { |n| n['data']['id'] }
      current_nodes = workflow_content['nodes'] || []
      current_node_ids = current_nodes.map { |n| n['data']['id'] }

      added_node_ids = (current_node_ids - old_node_ids)
      removed_node_ids =  (old_node_ids - current_node_ids)
      modified_node_ids = (current_nodes - old_nodes).map { |n| n['data']['id'] } - added_node_ids

      # Resolve the actual nodes from the IDs
      added_nodes = added_node_ids.map { |i| workflow_content['nodes'].detect { |n| n['data']['id'] == i } }
      removed_nodes = removed_node_ids.map do |i|
        workflow_content_before_last_save['nodes'].detect do |n|
          n['data']['id'] == i
        end
      end
      modified_nodes = modified_node_ids.map { |i| workflow_content['nodes'].detect { |n| n['data']['id'] == i } }

      if added_node_ids.any? || removed_node_ids.any? || modified_node_ids.any?
        create_activity :modify_diagram, owner: User.current_user,
                                         parameters: {
                                           added_nodes: added_nodes,
                                           removed_nodes: removed_nodes,
                                           modified_nodes: modified_nodes
                                         }
      end
    end
  end

  def node_index(type)
    results = []
    workflow_content['nodes']&.each do |node|
      results << node['data'][type]
    end
    results
  end

  # Stop the huge JSON blob being printed in the console when inspecting a workflow
  def attribute_for_inspect(attr)
    attr.to_s == 'workflow_content' ? super[0..100] : super
  end

  def self.visible_by(user)
    if user&.is_admin?
      all
    elsif user
      references(:collaborations).includes(:collaborations)
                                 .where("#{table_name}.public = :public OR #{table_name}.user_id = :user OR collaborations.user_id = :user",
                                        public: true, user: user)
    else
      where(public: true)
    end
  end

  def loggable_changes
    super - %w[workflow_content]
  end
end
