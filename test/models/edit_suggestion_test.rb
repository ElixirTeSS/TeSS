require 'test_helper'

class EditSuggestionTest < ActiveSupport::TestCase
  test 'should remove a topic by uri' do
    suggestion = edit_suggestions(:one)

    assert_difference(-> { suggestion.scientific_topics.count }, -1) do
      suggestion.reject_suggestion(suggestion.scientific_topics.first)
    end
  end

  test 'should add a topic by uri' do
    suggestion = edit_suggestions(:one)
    resource = suggestion.suggestible

    assert_difference(-> { suggestion.scientific_topics.count }, -1) do
      assert_difference(-> { resource.scientific_topics.count }, 1) do
        suggestion.accept_suggestion(suggestion.scientific_topics.first)
      end
    end
  end

  test 'should not delete topic if bad uri' do
    suggestion = edit_suggestions(:one)

    assert_no_difference(-> { suggestion.scientific_topics.count }) do
      suggestion.reject_suggestion(EDAM::Ontology.instance.lookup('http://edamontology.org/topic_0078'))
    end
  end

  test 'should not add topic if bad uri' do
    suggestion = edit_suggestions(:one)
    resource = suggestion.suggestible

    assert_no_difference(-> { suggestion.scientific_topics.count }) do
      assert_no_difference(-> { resource.scientific_topics.count }) do
        suggestion.accept_suggestion(EDAM::Ontology.instance.lookup('http://edamontology.org/topic_0078'))
      end
    end
  end

  test 'should destroy edit suggestion when no topics left' do
    suggestion = edit_suggestions(:one)
    topic1 = suggestion.scientific_topics.first
    topic2 = suggestion.scientific_topics.last

    assert_difference('EditSuggestion.count', -1) do
      assert_difference(-> { suggestion.scientific_topics.count }, -2) do
        suggestion.reject_suggestion(topic1)
        suggestion.reject_suggestion(topic2)
      end
    end
  end

  test 'should destroy associated scientific_topic_links on destroy' do
    suggestion = edit_suggestions(:one)
    assert_equal 2, suggestion.scientific_topic_links.count

    assert_difference('EditSuggestion.count', -1) do
      assert_difference('ScientificTopicLink.count', -2) do
        suggestion.destroy
      end
    end
  end
end
