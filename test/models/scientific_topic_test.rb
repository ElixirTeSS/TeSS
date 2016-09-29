require 'test_helper'

class ScientificTopicTest < ActiveSupport::TestCase

  test 'can seed scientific topics' do
    original_count = ScientificTopic.count

    ScientificTopic.create_topics

    assert ScientificTopic.count > original_count
  end

  test 'can safely seed scientific topics multiple times' do
    ScientificTopic.create_topics
    old_topics = ScientificTopic.limit(20).to_yaml

    ScientificTopic.create_topics
    new_topics = ScientificTopic.limit(20).to_yaml

    assert_equal old_topics, new_topics
  end

  test 'no blank array elements in scientific topics' do
    ScientificTopic.create_topics

    array_fields = [:synonyms, :definitions, :parents, :consider, :has_alternative_id, :has_broad_synonym,
                    :has_narrow_synonym, :has_dbxref, :has_exact_synonym, :has_related_synonym, :has_subset, :in_subset,
                    :replaced_by, :subset_property, :in_cyclic]

    ScientificTopic.all.each do |topic|
      array_fields.each do |field|
        assert topic.send(field).none?(&:blank?), "ScientificTopic '#{topic.class_id}' has blank value in field '#{field}'"
      end
    end
  end

end
