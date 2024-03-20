# frozen_string_literal: true

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

    return unless results.any?

    @term_class.new(self, results)
  end

  private

  def parse
    cache do
      Rails.logger.info("Loading ontology: #{@filename}")
      reader = RDF::Reader.for(:rdfxml).new(File.open(path))

      RDF::Graph.new.tap do |graph|
        graph << reader
      end
    end
  end

  def cache(&block)
    filename = cache_path
    if File.exist?(filename)
      File.open(filename) { |f| Marshal.load(f.read) }
    else
      result = block.call
      File.atomic_write(filename) { |f| f.write(Marshal.dump(result)) }
      result
    end
  end

  def path
    File.join(Rails.root, 'config', 'ontologies', @filename)
  end

  def cache_path
    "#{path}--linkeddata-#{Gem.loaded_specs['linkeddata'].version}.cache"
  end
end
