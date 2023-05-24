# frozen_string_literal: true

module HasAssociatedNodes
  extend ActiveSupport::Concern

  included do
    has_many :node_links, as: :resource
    has_many :nodes, through: :node_links
  end

  def has_node?
    nodes.any? || content_provider&.node_id
  end

  def associated_nodes
    n = nodes.to_a
    n << content_provider.node if content_provider

    n.compact.uniq
  end

  def node_names=(names)
    nodes = Node.where(name: names).to_a

    self.nodes = nodes
  end

  def node_names
    nodes.map(&:name)
  end

  def associated_node_names
    associated_nodes.map(&:name)
  end
end
