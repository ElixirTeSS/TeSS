require 'test_helper'

class EditSuggestionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  setup do

  end
  test "should_remove_a_topic_by_uri" do
    suggestion = edit_suggestions(:one)
    assert_equal 2, suggestion.scientific_topics.count
    assert_not_nil suggestion.drop_topic({:uri => scientific_topic_links(:term_two).term_uri})
    assert_equal 1, suggestion.scientific_topics.count
  end

  test "should_return_nil_if_remove_non_existent_topic" do
    suggestion = edit_suggestions(:one)
    assert_equal 2, suggestion.scientific_topics.count
    assert_nil suggestion.drop_topic({:uri => 'total_gibberish'})
    assert_equal 2, suggestion.scientific_topics.count
  end
end
