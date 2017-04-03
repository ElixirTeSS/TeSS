require 'test_helper'

class MaterialsHelperTest < ActionView::TestCase

  test "edam file loaded successfully" do
    topics = scientific_topic_names_for_autocomplete
    assert_equal topics.class, Array
    assert_not_empty topics
    assert_includes topics, 'Metabolomics'
  end

end
