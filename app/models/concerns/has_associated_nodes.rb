module HasAssociatedNodes

  extend ActiveSupport::Concern

  included do
    has_many :node_links, as: :resource
    has_many :nodes, through: :node_links
  end

  def associated_nodes
    n = self.nodes.to_a
    n << self.content_provider.node if self.content_provider

    n.compact.uniq
  end

end
