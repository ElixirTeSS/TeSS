module EDAM
  class Term < ::OntologyTerm
    def preferred_label
      data[RDF::RDFS.label].first.value
    end

    def has_exact_synonym
      data[OBO.hasExactSynonym] ? data[OBO.hasExactSynonym].map(&:value) : []
    end
    alias_method :synonyms, :has_exact_synonym

    def has_narrow_synonym
      data[OBO.hasNarrowSynonym] ? data[OBO.hasNarrowSynonym].map(&:value) : []
    end

    def has_broad_synonym
      data[OBO.hasBroadSynonym] ? data[OBO.hasBroadSynonym].map(&:value) : []
    end

    def inspect
      "<#{self.class} @ontology=#{self.ontology.class.name}, @uri=#{self.uri}, preferred_label: #{self.preferred_label}>"
    end
  end
end
