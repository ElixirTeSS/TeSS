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

end
