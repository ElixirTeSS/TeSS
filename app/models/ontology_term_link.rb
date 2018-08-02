class OntologyTermLink < ApplicationRecord
  belongs_to :resource, polymorphic: true

  def ontology_term
    ontology.lookup(term_uri)
  end

  def ontology
    EDAM::Ontology.instance
  end
end
