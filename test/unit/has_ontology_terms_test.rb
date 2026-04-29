require 'test_helper'

class HasOntologyTermsTest < ActiveSupport::TestCase
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
    # A very permissive ontology: it allows any term
    include Singleton

    def initialize
    end

    def uri
      'http://dummy/'
    end

    def scoped_lookup_by_name(term, subset = :_)
      return DummyTerm.new(term)
    end

    def lookup(uri)
      term = uri[/http:\/\/dummy\/(.*)/,1]
      return DummyTerm.new(term)
    end
  end

  class DummyMaterial < ::Material
    has_ontology_terms(:test_topics, ontology: DummyOntology.instance)

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

  test 'can create an attribute with ontology terms' do
    dummy = materials(:good_material).becomes(DummyMaterial)
    dummy.test_topic_names = ['Bioinformatics']
    dummy.save!

    assert_equal dummy.test_topics.count, 1
    assert_equal dummy.test_topic_names, ['Bioinformatics'] 
    assert_equal dummy.test_topic_uris, ['http://dummy/Bioinformatics'] 
  end
end
