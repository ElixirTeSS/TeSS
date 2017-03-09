class Ontology

  def initialize(filename, term_class = OntologyTerm)
    @filename = filename
    @term_class = term_class
  end

  def lookup(uri)
    @cache ||= {}
    @cache[RDF::URI(uri)] ||= fetch(uri)
  end

  def graph
    @graph ||= parse
  end

  def load
    @graph = parse
  end

  def fetch(uri)
    query([RDF::URI(uri), :p, :o])
  end

  def query(q)
    results = graph.query(q)

    if results.any?
      @term_class.new(self, results)
    else
      nil
    end
  end

  private

  def parse
    reader = RDF::Reader.for(:rdfxml).new(File.open(path))

    Rails.logger.info("Loading ontology: #{@filename}")
    RDF::Graph.new.tap do |graph|
      graph << reader
    end
  end

  def path
    File.join(Rails.root, 'config', 'ontologies', @filename)
  end

end
