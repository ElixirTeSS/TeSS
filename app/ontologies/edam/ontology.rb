module Edam
  class Ontology < ::Ontology
    include Singleton

    def initialize
      super('EDAM_unstable-1.26_dev.owl', Edam::Term)
    end

    def uri
      'http://edamontology.org'
    end

    def all_topics
      find_by(OBO.inSubset, OBO_EDAM.topics)
    end

    def all_operations
      find_by(OBO.inSubset, OBO_EDAM.operations)
    end

    def lookup_by_name(name)
      lookup_by(RDF::RDFS.label, name)
    end

    def scoped_lookup_by_name(name, subset = :_)
      query = RDF::Query.new do
        pattern [:u, RDF::RDFS.label, name]
        pattern [:u, OBO.inSubset, subset]
      end

      result = graph.query(query).first
      lookup(result.u) if result
    end
  end
end
