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
      @cache = {}
    end

    def lookup(uri)
      @ontology.lookup(uri)
    end

    def lookup_by_name(name)
      lookup_by(RDF::RDFS.label, name)
    end

    def lookup_by(predicate, object)
      @cache[predicate] ||= {}

      if @cache[predicate].key?(object)
        @cache[predicate][object]
      else
        @cache[predicate][object] = @ontology.lookup_by(predicate, object)
      end
    end
  end

end
