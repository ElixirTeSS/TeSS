module EDAM
  class Ontology < ::Ontology
    include Singleton

    def initialize
      super('EDAM_1.20.owl', EDAM::Term)
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

    def lookup_topic_by_name(name)
      query = RDF::Query.new do
        pattern [:u, RDF::RDFS.label, name]
        pattern [:u, OBO.inSubset, OBO_EDAM.topics]
      end

      result = graph.query(query).first
      lookup(result.u) if result
    end
  end
end
