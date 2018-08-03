module EDAM
  class Term < ::OntologyTerm
    alias_method :preferred_label, :label

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

    def subclasses
      @subclasses ||= ontology.find_by(RDF::RDFS.subClassOf, RDF::URI(uri))
    end

    def parent
      return @parent if defined? @parent
      @parent = (data[RDF::RDFS.subClassOf] ? ontology.lookup(data[RDF::RDFS.subClassOf].first) : nil)
    end

    def parent_uri
      parent ? parent.uri : nil
    end

    def deprecated?
      data[RDF::OWL.deprecated] ? data[RDF::OWL.deprecated].first.value != 'false' : false
    end
  end
end
