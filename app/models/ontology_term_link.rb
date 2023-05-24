# frozen_string_literal: true

class OntologyTermLink < ApplicationRecord
  belongs_to :resource, polymorphic: true

  def ontology_term
    ontology.lookup(term_uri)
  end

  def ontology
    Edam::Ontology.instance
  end
end
