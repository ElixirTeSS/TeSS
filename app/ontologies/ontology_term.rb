# frozen_string_literal: true

class OntologyTerm
  attr_reader :ontology, :data, :uri

  def initialize(ontology, statements)
    @ontology = ontology
    @data = {}
    @uri = statements.first.subject.to_s

    statements.each do |statement|
      @data[statement.predicate] ||= []
      @data[statement.predicate] << statement.object
    end
  end

  def label
    data[RDF::RDFS.label].first.try(:value)
  end

  def ==(other)
    return super unless other.is_a?(OntologyTerm)

    uri == other.uri
  end

  delegate :hash, to: :uri

  alias eql? ==

  def inspect
    "<#{self.class} @ontology=#{ontology.class.name}, @uri=#{uri}, label: #{label}>"
  end
end
