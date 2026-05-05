class OntologyTermLink < ApplicationRecord
  belongs_to :resource, polymorphic: true

  def ontology_term
    ontology&.lookup(term_uri)
  end

  def ontology
    @ontology ||= Ontology.subclasses.map(&:instance).\
                    find { |ontology| ontology.term_uri_matches?(term_uri) }
  end
end
