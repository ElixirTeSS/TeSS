require 'test_helper'

class EditSuggestionTest < ActiveSupport::TestCase
  test 'should remove a topic by uri' do
    suggestion = edit_suggestions(:one)

    assert_difference(-> { suggestion.scientific_topics.count }, -1) do
      suggestion.reject_suggestion('scientific_topics', suggestion.scientific_topics.first)
    end
  end

  test 'should add a topic by uri' do
    suggestion = edit_suggestions(:one)
    resource = suggestion.suggestible

    assert_difference(-> { suggestion.scientific_topics.count }, -1) do
      assert_difference(-> { resource.reload.scientific_topics.count }, 1) do
        suggestion.accept_suggestion('scientific_topics', suggestion.scientific_topics.first)
      end
    end
  end

  test 'should add an operation by uri' do
    resource = materials(:good_material)
    suggestion = resource.build_edit_suggestion
    term = EDAM::Ontology.instance.lookup('http://edamontology.org/operation_2931')
    suggestion.operations = [term]
    suggestion.save!

    assert_difference(-> { suggestion.operations.count }, -1) do
      assert_difference(-> { resource.reload.operations.count }, 1) do
        suggestion.accept_suggestion('operations', term)
      end
    end
  end

  test 'should not add unsupported field' do
    resource = materials(:good_material)
    suggestion = resource.create_edit_suggestion
    term = EDAM::Ontology.instance.lookup('http://edamontology.org/operation_2931')
    suggestion.ontology_term_links.create!(term_uri: term.uri, field: 'bananas')

    assert_no_difference(-> { resource.reload.ontology_term_links.count }) do
      suggestion.accept_suggestion('bananas', term)
    end
  end

  test 'should not delete topic if bad uri' do
    suggestion = edit_suggestions(:one)

    assert_no_difference(-> { suggestion.scientific_topics.count }) do
      suggestion.reject_suggestion('scientific_topics', EDAM::Ontology.instance.lookup('http://edamontology.org/topic_0078'))
    end
  end

  test 'should not add topic if bad uri' do
    suggestion = edit_suggestions(:one)
    resource = suggestion.suggestible

    assert_no_difference(-> { suggestion.scientific_topics.count }) do
      assert_no_difference(-> { resource.scientific_topics.count }) do
        suggestion.accept_suggestion('scientific_topics', EDAM::Ontology.instance.lookup('http://edamontology.org/topic_0078'))
      end
    end
  end

  test 'should destroy edit suggestion when no topics left' do
    suggestion = edit_suggestions(:one)
    topic1 = suggestion.scientific_topics.first
    topic2 = suggestion.scientific_topics.last

    assert_difference('EditSuggestion.count', -1) do
      assert_difference(-> { suggestion.scientific_topics.count }, -2) do
        suggestion.reject_suggestion('scientific_topics', topic1)
        suggestion.reject_suggestion('scientific_topics', topic2)
      end
    end
  end

  test 'should destroy associated scientific_topic_links on destroy' do
    suggestion = edit_suggestions(:one)
    assert_equal 2, suggestion.scientific_topic_links.count

    assert_difference('EditSuggestion.count', -1) do
      assert_difference('OntologyTermLink.count', -2) do
        suggestion.destroy
      end
    end
  end

  test "should remove a data field by name" do
    suggestion = edit_suggestions(:two)
    assert_equal 1, suggestion.data_fields.count
    assert_equal 'banana', suggestion.data_fields.delete('fruit')
    assert_equal 0, suggestion.data_fields.count
  end

  test "should return nil if remove non existent data field" do
    suggestion = edit_suggestions(:two)
    assert_equal 1, suggestion.data_fields.count
    assert_nil suggestion.data_fields.delete('vegetable')
    assert_equal 1, suggestion.data_fields.count
  end

  test 'should delete edit suggestion once all data fields have gone' do
    suggestion = edit_suggestions(:multiple_fields)
    event = suggestion.suggestible
    assert_equal 2, suggestion.data_fields.count

    assert_nil event.reload.latitude

    assert_no_difference('EditSuggestion.count') do
      suggestion.accept_data('latitude')
    end

    assert_equal 15, event.reload.latitude

    assert_difference('EditSuggestion.count', -1) do
      suggestion.reject_data('title')
    end

    assert_not_equal 'banana', event.reload.title
  end

end
