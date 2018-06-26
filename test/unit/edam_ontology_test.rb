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
      topic = EDAM::Ontology.instance.scoped_lookup_by_name(label, OBO_EDAM.topics)

      assert topic
      assert_match /.+topic_/, topic.uri
    end
  end

  test 'should fetch term subclasses' do
    term = EDAM::Ontology.instance.lookup_by_name('Proteins')

    assert_equal 9, term.subclasses.length
    assert_includes term.subclasses.map(&:label), 'Enzymes'

    another_term = EDAM::Ontology.instance.lookup_by_name('Membrane and lipoproteins')
    assert_empty another_term.subclasses
  end

  test 'should fetch term parent' do
    term = EDAM::Ontology.instance.lookup_by_name('Membrane and lipoproteins')

    assert_equal 'Proteins', term.parent.label
    assert_equal 'Computational biology', term.parent.parent.label
    assert_equal 'Topic', term.parent.parent.parent.label
    assert_nil term.parent.parent.parent.parent
  end

  test 'should lookup deprecated term' do
    deprecated_term = EDAM::Ontology.instance.lookup('http://edamontology.org/operation_2931')
    term = EDAM::Ontology.instance.lookup_by_name('Proteins')

    assert deprecated_term.deprecated?
    refute term.deprecated?
  end

  test 'should compare term objects by URI' do
    term1 = EDAM::Ontology.instance.lookup_by_name('Proteins')
    term2 = EDAM::Ontology.instance.fetch('http://edamontology.org/topic_0078')

    assert_not_equal term1.object_id, term2.object_id, 'Terms should be different Ruby objects in memory'
    assert_equal term1.uri, term2.uri
    assert term1 == term2
    assert term1.eql?(term2)
    assert [term1] == [term2]
    assert_empty [term1] - [term2]
  end

  test 'scoped name lookup' do
    assert EDAM::Ontology.instance.scoped_lookup_by_name('Proteins', OBO_EDAM.topics)
    refute EDAM::Ontology.instance.scoped_lookup_by_name('Proteins', OBO_EDAM.operations)

    refute EDAM::Ontology.instance.scoped_lookup_by_name('Analysis', OBO_EDAM.topics)
    assert EDAM::Ontology.instance.scoped_lookup_by_name('Analysis', OBO_EDAM.operations)

    assert EDAM::Ontology.instance.scoped_lookup_by_name('Sequence analysis', OBO_EDAM.topics)
    assert EDAM::Ontology.instance.scoped_lookup_by_name('Sequence analysis', OBO_EDAM.operations)

    refute EDAM::Ontology.instance.scoped_lookup_by_name('Monster trucks', OBO_EDAM.topics)
    refute EDAM::Ontology.instance.scoped_lookup_by_name('Monster trucks', OBO_EDAM.operations)

    # Allow unscoping of the scoped lookup!
    assert EDAM::Ontology.instance.scoped_lookup_by_name('Proteins', :_)
    assert EDAM::Ontology.instance.scoped_lookup_by_name('Analysis', :_)

    assert EDAM::Ontology.instance.scoped_lookup_by_name('Proteins')
    assert EDAM::Ontology.instance.scoped_lookup_by_name('Analysis')
  end
end
