require 'test_helper'

class EdamOntologyTest < ActiveSupport::TestCase

  test 'should lookup term' do
    term = EDAM::Ontology.instance.lookup('http://edamontology.org/topic_0078')

    assert term
    assert_equal 'Proteins', term.preferred_label
    assert_includes term.synonyms, 'Protein informatics'
    assert_includes term.synonyms, 'Protein bioinformatics'

    term = EDAM::Ontology.instance.lookup('http://edamontology.org/topic_0624')

    assert term
    assert_equal 'Chromosomes', term.preferred_label
    assert_empty term.synonyms
  end

  test 'should lookup term by name' do
    term = EDAM::Ontology.instance.lookup_by_name('Proteins')

    assert term
    assert_equal 'Proteins', term.preferred_label
    assert_includes term.synonyms, 'Protein informatics'
    assert_includes term.synonyms, 'Protein bioinformatics'
  end

  test 'should find terms by any predicate' do
    terms = EDAM::Ontology.instance.find_by(OBO.hasNarrowSynonym, 'DNA microarrays')

    assert 1, terms.count
    assert_equal 'Gene expression', terms.first.preferred_label
  end


end
