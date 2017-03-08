class Ontology

  def initialize(filename, term_class = OntologyTerm)
    @filename = filename
    @term_class = term_class
  end

  def lookup(uri)
    results = graph.query([RDF::URI(uri), :p, :o])

    if results.any?
      @term_class.new(self, results)
    else
      nil
    end
  end

  def graph
    @graph ||= load
  end

  def load
    @graph = parse
  end

  private

  def parse
    reader = RDF::Reader.for(:rdfxml).new(File.open(path))

    RDF::Graph.new.tap do |graph|
      graph << reader
    end
  end

  def path
    File.join(Rails.root, 'config', 'ontologies', @filename)
  end

end
