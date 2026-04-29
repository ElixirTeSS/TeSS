require 'test_helper'

class HasOntologyTermsTest < ActiveSupport::TestCase
  # Summary: we create attributes 'test_topics' and 'multi_test_topics' for
  # the fake model DummyMaterial. 'test_topics' uses DummyOntology,
  # 'multi_test_topics' uses both DummyOntology and Edam::Ontology

  teardown do
    DummyMaterial.clear_index!
  end

  class DummyTerm
    attr_reader :label, :uri
    def initialize(term)
      @label = term
      @uri = "http://dummy/#{term}"
    end
    alias_method :preferred_label, :label
  end

  class DummyOntology < ::Ontology
    # A very permissive ontology: it allows any term as long as it doesn't have Chemistry in it
    include Singleton

    def initialize
    end

    def uri
      'http://dummy/'
    end

    def scoped_lookup_by_name(term, subset = :_)
      return DummyTerm.new(term) unless term =~ /chemistry/i
    end
    alias_method :scoped_lookup_by_name_or_synonym, :scoped_lookup_by_name

    def lookup(uri)
      term = uri[/http:\/\/dummy\/(.*)/,1]
      return DummyTerm.new(term) unless term.blank?
    end
  end

  class DummyMaterial < ::Material
    has_ontology_terms(:test_topics, ontology: DummyOntology.instance)
    has_ontology_terms(:multi_test_topics,
                       ontologies: [{ ontology: Edam::Ontology.instance,
                                      branch: EDAM.topics},
                                    { ontology: DummyOntology.instance}])

    # TODO: see similar tests with model subclasses, maybe can be in a module?
    def self.index
      (@index ||= Hash.new).values.flatten.uniq
    end

    def self.add_to_index(m)
      index
      @index[m.id] = m.reload.collections.to_a
    end

    def self.clear_index!
      @index = Hash.new
    end

    def solr_index
      self.class.add_to_index(self)
    end
  end

  test 'can create an attribute with terms from a single ontology' do
    # See the Event/Material model tests for many examples of this ...
    dummy = materials(:good_material).becomes(DummyMaterial)

    # This is found in the ontology ...
    dummy.test_topic_names = ['Bioinformatics']
    dummy.save!
    assert_equal dummy.test_topics.count, 1
    assert_equal dummy.test_topic_names, ['Bioinformatics']
    assert_equal dummy.test_topic_uris, ['http://dummy/Bioinformatics']

    # This is not
    dummy.test_topic_names = ['Biochemistry']
    dummy.save!
    assert_equal dummy.test_topics.count, 0
    assert_equal dummy.test_topic_names, []
    assert_equal dummy.test_topic_uris, []
  end

  test 'can create an attribute with terms from multiple ontologies' do
    dummy = materials(:good_material).becomes(DummyMaterial)

    # This is found in both ontologies ...
    dummy.multi_test_topic_names = ['Bioinformatics']
    dummy.save!
    assert_equal dummy.multi_test_topics.count, 2
    assert_equal Set.new(dummy.multi_test_topic_uris),
                 Set.new(['http://edamontology.org/topic_0091', 'http://dummy/Bioinformatics'])
    # The two exact names collapse into one ...
    assert_equal dummy.multi_test_topic_names, ['Bioinformatics']

    # This is found in only in Edam ...
    dummy.multi_test_topic_names = ['Biochemistry']
    dummy.save!
    assert_equal dummy.multi_test_topics.count, 1
    assert_equal dummy.multi_test_topic_names, ['Biochemistry']
    assert_equal dummy.multi_test_topic_uris, ['http://edamontology.org/topic_3292']

    # This is found only in DummyOntology ...
    dummy.multi_test_topic_names = ['Poodles']
    dummy.save!
    assert_equal dummy.multi_test_topics.count, 1
    assert_equal dummy.multi_test_topic_names, ['Poodles']
    assert_equal dummy.multi_test_topic_uris, ['http://dummy/Poodles']

    # This is found in neither ...
    dummy.multi_test_topic_names = ['Poodle Chemistry']
    dummy.save!
    assert_equal dummy.multi_test_topics.count, 0
    assert_equal dummy.multi_test_topic_names, []
    assert_equal dummy.multi_test_topic_uris, []

    # Set via URIs
    dummy.multi_test_topic_uris = ['http://dummy/Poodles',
                                   'http://edamontology.org/topic_3292']
    dummy.save!
    assert_equal dummy.multi_test_topics.count, 2
    assert_equal Set.new(dummy.multi_test_topic_names),
                 Set.new(['Biochemistry', 'Poodles'])
    assert_equal Set.new(dummy.multi_test_topic_uris),
                 Set.new(['http://dummy/Poodles',
                          'http://edamontology.org/topic_3292'])
    assert_equal dummy.ontology_term_links.map(&:field), ["multi_test_topics",
                                                          "multi_test_topics"]
    assert_equal Set.new(dummy.ontology_term_links.map(&:term_uri)),
                 Set.new(['http://dummy/Poodles',
                          'http://edamontology.org/topic_3292'])
  end
end
