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

  def ==(other)
    self.uri == other.uri
  end

end
