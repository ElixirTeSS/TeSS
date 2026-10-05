require 'test_helper'

class MaterialsHelperTest < ActionView::TestCase
  test 'edam file loaded successfully' do
    topics = scientific_topic_names_for_autocomplete
    assert_equal topics.class, Array
    assert_not_empty topics
    assert_includes topics, 'Metabolomics'
  end

  test 'keywords_and_topics generates spans with css classes for scientific topics and operations' do
    topic_term = OpenStruct.new(preferred_label: 'Genomics', uri: 'http://edamontology.org/topic_0622')
    operation_term = OpenStruct.new(preferred_label: 'Sequence alignment', uri: 'http://edamontology.org/operation_0292')
    resource = OpenStruct.new(
      scientific_topics: [topic_term],
      operations: [operation_term],
      keywords: %w[keyword1 keyword2]
    )
    result = keywords_and_topics(resource)

    assert_includes result, 'Genomics'
    assert_includes result, 'tag-topic'
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

  test 'approval_options_for_select_material returns mapped array of translated pairs' do
    options = approval_options_for_select_material

    assert_kind_of Array, options
    assert_equal Material::APPROVAL_STATUS.values.size, options.size

    Material::APPROVAL_STATUS.values.each do |status|
      expected_label = I18n.t("materials.approval_status.#{status}")
      assert_includes options, [expected_label, status]
    end
  end

  test 'material_enabled_badge renders success label when true' do
    badge = material_enabled_badge(true)

    assert_dom_equal '<span class="label label-success">Enabled</span>', badge
  end

  test 'material_enabled_badge renders danger label when false' do
    badge = material_enabled_badge(false)

    assert_dom_equal '<span class="label label-danger">Disabled</span>', badge
  end

  test 'material_approval_badge renders correct labels for each status' do
    statuses = {
      not_approved: 'label-danger',
      requested: 'label-warning',
      approved: 'label-success'
    }

    statuses.each do |status, expected_class|
      label_text = I18n.t("materials.approval_status.#{status}")
      
      [status, status.to_s].each do |input|
        badge = material_approval_badge(input)
        assert_dom_equal "<span class=\"label #{expected_class}\">#{label_text}</span>", badge
      end
    end
  end

  test 'material_approval_badge returns nil for unknown status' do
    assert_nil material_approval_badge(:unknown_status)
  end
end

