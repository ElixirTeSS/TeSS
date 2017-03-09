require 'test_helper'

class EdamOntologyTest < ActiveSupport::TestCase

  test 'should lookup proteins term' do
    term = EDAM::Ontology.instance.lookup('http://edamontology.org/topic_0078')

    assert term
    assert_equal 'Proteins', term.preferred_label
    assert_includes term.synonyms, 'Protein informatics'
    assert_includes term.synonyms, 'Protein bioinformatics'
  end

  test 'should lookup proteins term by name' do
    term = EDAM::Ontology.instance.lookup_by_name('Proteins')

    assert term
    assert_equal 'Proteins', term.preferred_label
    assert_includes term.synonyms, 'Protein informatics'
    assert_includes term.synonyms, 'Protein bioinformatics'
  end

end
