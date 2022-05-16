module T4fs
  class Ontology < ::Ontology
    include Singleton

    def initialize
      super('t4fs.owl', T4fs::Term)
    end

    def terms
      find_by(RDF::RDFV.type, RDF::OWL.Class)
    end

    def scoped_lookup_by_name(name, subset = :_)
      query = RDF::Query.new do
        pattern [:u, RDF::RDFS.label, name]
      end

      result = graph.query(query).first
      lookup(result.u) if result
    end
  end
end
