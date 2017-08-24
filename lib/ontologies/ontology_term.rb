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
    self.uri == other.uri
  end

  def inspect
    "<#{self.class} @ontology=#{self.ontology.class.name}, @uri=#{self.uri}, label: #{self.label}>"
  end
end
