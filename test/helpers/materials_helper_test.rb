require 'test_helper'

class MaterialsHelperTest < ActionView::TestCase
  test 'edam file loaded successfully' do
    topics = scientific_topic_names_for_autocomplete
    assert_equal topics.class, Array
    assert_not_empty topics
    assert_includes topics, 'Metabolomics'
  end

  test 'keywords_and_topics generates clickable links for scientific topics and operations' do
    topic_term = OpenStruct.new(preferred_label: 'Genomics', uri: 'http://edamontology.org/topic_0622')
    operation_term = OpenStruct.new(preferred_label: 'Sequence alignment', uri: 'http://edamontology.org/operation_0292')
    resource = OpenStruct.new(
      scientific_topics: [topic_term],
      operations: [operation_term],
      keywords: %w[keyword1 keyword2]
    )
    result = keywords_and_topics(resource)

    assert_includes result, 'href="http://edamontology.org/topic_0622"'
    assert_includes result, 'Genomics'
    assert_includes result, 'tag-topic'
    assert_includes result, 'href="http://edamontology.org/operation_0292"'
    assert_includes result, 'Sequence alignment'
    assert_includes result, 'tag-operation'
    assert_includes result, 'keyword1'
    assert_includes result, 'keyword2'
  end

  test 'keywords_and_topics handles missing attributes' do
    resource = OpenStruct.new

    result = keywords_and_topics(resource)
    assert_equal '', result
  end

  test 'keywords_and_topics with limit' do
    topic_term = OpenStruct.new(preferred_label: 'Genomics', uri: 'http://edamontology.org/topic_0622')
    resource = OpenStruct.new(
      scientific_topics: [topic_term],
      keywords: %w[keyword1 keyword2 keyword3]
    )
    result = keywords_and_topics(resource, limit: 2)

    assert_includes result, '&hellip;'
  end
end
