class OntologyTerm

  attr_reader :ontology, :data

  def initialize(ontology, statements)
    @ontology = ontology
    @data = {}

    statements.each do |statement|
      @data[statement.predicate] ||= []
      @data[statement.predicate] << statement.object
    end
  end

end