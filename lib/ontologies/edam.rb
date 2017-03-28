OBO = RDF::Vocabulary.new('http://www.geneontology.org/formats/oboInOwl#')
OBO_EDAM = RDF::Vocabulary.new('http://purl.obolibrary.org/obo/edam#')

module EDAM

  class Term < ::OntologyTerm

    def preferred_label
      data[RDF::RDFS.label].first.value
    end

    def synonyms
      has_exact_synonym
    end

    def has_exact_synonym
      data[OBO.hasExactSynonym] ? data[OBO.hasExactSynonym].map(&:value) : []
    end

    def has_narrow_synonym
      data[OBO.hasNarrowSynonym] ? data[OBO.hasNarrowSynonym].map(&:value) : []
    end

    def has_broad_synonym
      data[OBO.hasBroadSynonym] ? data[OBO.hasBroadSynonym].map(&:value) : []
    end

    def inspect
      "<#{self.class} @uri=#{self.uri}, preferred_label: #{self.preferred_label}>"
    end

  end

  class Ontology
    include Singleton

    attr_reader :ontology

    def initialize
      @ontology = ::Ontology.new('EDAM_1.16.owl', EDAM::Term)
      @cache = {}
    end

    def load
      @ontology.load
    end

    def all_topics
      find_by(OBO.inSubset, OBO_EDAM.topics)
    end

    def all_operations
      find_by(OBO.inSubset, OBO_EDAM.operations)
    end

    def lookup(uri)
      @ontology.lookup(uri)
    end

    def lookup_by_name(name)
      lookup_by(RDF::RDFS.label, name)
    end

    def find_by(predicate, object)
      @cache[predicate] ||= {}

      if @cache[predicate].key?(object)
        @cache[predicate][object]
      else
        @cache[predicate][object] = @ontology.find_by(predicate, object)
      end
    end

    def lookup_by(predicate, object)
      find_by(predicate, object).first
    end
  end

end
