OBO = RDF::Vocabulary.new('http://www.geneontology.org/formats/oboInOwl#')

module EDAM

  class Term < ::OntologyTerm

    def preferred_label
      data[RDF::RDFS.label].first.value
    end

    def synonyms
      data[OBO.hasExactSynonym].map(&:value)
    end

  end

  class Ontology
    include Singleton

    attr_reader :ontology

    def initialize
      @ontology = ::Ontology.new('EDAM_1.16.owl', EDAM::Term)
    end

    def lookup(uri)
      @ontology.lookup(uri)
    end

    def lookup_by_name(name)
      @name_cache ||= {}
      if @name_cache.key?(name)
        @name_cache[name]
      else
        uri = @ontology.graph.query([:u, RDF::RDFS.label, name]).first.subject
        @name_cache[name] = lookup(uri)
      end
    end
  end

end
