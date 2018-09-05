class Ontology
  def initialize(filename, term_class = OntologyTerm)
    @filename = filename
    @term_class = term_class
    @term_cache = {}
    @query_cache = {}
  end

  def lookup(uri)
    @term_cache[RDF::URI(uri)] ||= fetch(uri)
  end

  # Collection
  def find_by(predicate, object)
    @query_cache[predicate] ||= {}

    if @query_cache[predicate].key?(object)
      @query_cache[predicate][object]
    else
      results = graph.query([:u, predicate, object])
      @query_cache[predicate][object] = results.map { |result| lookup(result.subject) }
    end
  end

  # Singleton
  def lookup_by(predicate, object)
    find_by(predicate, object).first
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
