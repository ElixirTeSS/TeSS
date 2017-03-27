class Ontology

  def initialize(filename, term_class = OntologyTerm)
    @filename = filename
    @term_class = term_class
    @cache = {}
  end

  def lookup(uri)
    @cache[RDF::URI(uri)] ||= fetch(uri)
  end

  # Collection
  def find_by(predicate, object)
    results = graph.query([:u, predicate, object])
    results.map { |result| lookup(result.subject) }
  end

  # Singleton
  def lookup_by(predicate, object)
    result = graph.query([:u, predicate, object]).first
    lookup(result.subject) if result
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
