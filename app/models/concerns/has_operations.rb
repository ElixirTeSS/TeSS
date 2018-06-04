module HasOperations
  extend ActiveSupport::Concern

  included do
    unless method_defined?(:ontology_term_links)
      has_many :ontology_term_links, as: :resource, dependent: :destroy
    end
  end

  def operation_names= names
    terms = []
    [names].flatten.each do |name|
      unless name.blank?
        st = [EDAM::Ontology.instance.scoped_lookup_by_name(name, OBO_EDAM.topics)].compact
        st = EDAM::Ontology.instance.find_by(OBO.hasExactSynonym, name) if st.empty?
        st = EDAM::Ontology.instance.find_by(OBO.hasNarrowSynonym, name) if st.empty?
        terms += st
      end
    end
    self.operations = terms.uniq
  end

  def operation_names
    operations.map(&:preferred_label).uniq
  end

  def operations= terms
    self.ontology_term_links = terms.uniq.map { |term| ontology_term_links.build(term_uri: term.uri) if term && term.uri }.compact
  end

  def operations
    ontology_term_links.map(&:ontology_term).uniq
  end

  def operation_uris= uris
    self.operations = uris.map { |uri| EDAM::Ontology.instance.lookup(uri) }
  end

  def operation_uris
    self.operations.map(&:uri).uniq
  end
end
