module HasOperations
  extend ActiveSupport::Concern

  FIELD_NAME = 'operations'

  included do
    has_many :operation_links, -> { where(field: HasOperations::FIELD_NAME) }, class_name: 'OntologyTermLink', as: :resource, dependent: :destroy
  end

  def operation_names= names
    terms = []
    [names].flatten.each do |name|
      unless name.blank?
        st = [EDAM::Ontology.instance.scoped_lookup_by_name(name, OBO_EDAM.operations)].compact
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
    self.operation_links = terms.uniq.map { |term| operation_links.build(term_uri: term.uri) if term && term.uri }.compact
  end

  def operations
    operation_links.map(&:ontology_term).uniq
  end

  def operation_uris= uris
    self.operations = uris.map { |uri| EDAM::Ontology.instance.lookup(uri) }
  end

  def operation_uris
    self.operations.map(&:uri).uniq
  end
end
