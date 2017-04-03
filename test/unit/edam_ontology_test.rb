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

  test 'should lookup topic by name if ambiguous' do
    ['Mapping', 'Structure analysis', 'Nucleic acid structure analysis', 'Structure prediction',
     'Sequence assembly', 'Sequence analysis', 'Protein structure analysis'].each do |label|
      topic = EDAM::Ontology.instance.lookup_topic_by_name(label)

      assert topic
      assert_match /.+topic_/, topic.uri
    end
  end

end
