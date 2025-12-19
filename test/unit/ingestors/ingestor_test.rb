require 'test_helper'

class IngestorTest < ActiveSupport::TestCase
  test 'convert HTML descriptions to markdown where appropriate' do
    ingestor = Ingestors::Ingestor.new

    input = "### Title\n\nAmpersands & Quotes \""
    expected = input
    assert_equal expected, ingestor.convert_description(input)

    input = '<h1>Title</h1><ul><li>Item 1</li><li>Item 2</li>'
    expected = "# Title\n\n- Item 1\n- Item 2"
    assert_equal expected, ingestor.convert_description(input)
  end

  test 'sets event language from source default language' do
    user = users(:scraper_user)
    provider = content_providers(:portal_provider)

    # Source has default language set
    @source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                             enabled: true, approval_status: 'approved',
                             default_language: 'fr',
                             content_provider: provider, user: users(:admin))

    ingestor = Ingestors::Ingestor.new

    # Fake an event that was read ... no language set
    ingestor.instance_variable_set(:@events,
                                   [OpenStruct.new(url: 'https://some-course.ca',
                                                   title: 'Some course',
                                                   start: '2021-01-31 13:00:00',
                                                   end: '2021-01-31 14:00:00')])
    assert_difference('provider.events.count', 1) do
      ingestor.write(user, provider, source: @source)
    end
    event = Event.find_by(title: 'Some course')
    assert_equal(event.language, 'fr')
  end

  test 'does not override event language from source default language when language set' do
    user = users(:scraper_user)
    provider = content_providers(:portal_provider)

    # Source has default language set
    @source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                             enabled: true, approval_status: 'approved',
                             default_language: 'fr',
                             content_provider: provider, user: users(:admin))

    ingestor = Ingestors::Ingestor.new

    # Fake an event that was read ... with language set
    ingestor.instance_variable_set(:@events,
                                   [OpenStruct.new(url: 'https://some-course.de',
                                                   title: 'Some german course',
                                                   start: '2021-01-31 13:00:00',
                                                   end: '2021-01-31 14:00:00',
                                                   language: 'de')])
    assert_difference('provider.events.count', 1) do
      ingestor.write(user, provider, source: @source)
    end
    event = Event.find_by(title: 'Some german course')
    assert_equal(event.language, 'de')
  end

  test 'does not override event language when source default language missing' do
    user = users(:scraper_user)
    provider = content_providers(:portal_provider)

    # Source has no default language set
    @source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                             enabled: true, approval_status: 'approved',
                             content_provider: provider, user: users(:admin))

    ingestor = Ingestors::Ingestor.new

    # Fake an event that was read ... with language set
    ingestor.instance_variable_set(:@events,
                                   [OpenStruct.new(url: 'https://some-course.org',
                                                   title: 'Some other course',
                                                   start: '2021-01-31 13:00:00',
                                                   end: '2021-01-31 14:00:00',
                                                   language: 'de')])
    assert_difference('provider.events.count', 1) do
      ingestor.write(user, provider, source: @source)
    end
    event = Event.find_by(title: 'Some other course')
    assert_equal(event.language, 'de')
  end

  test 'does not set event language when languare and source default language missing' do
    user = users(:scraper_user)
    provider = content_providers(:portal_provider)

    # Source has no default language set
    @source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                             enabled: true, approval_status: 'approved',
                             content_provider: provider, user: users(:admin))

    ingestor = Ingestors::Ingestor.new

    # Fake an event that was read ... no language set
    ingestor.instance_variable_set(:@events,
                                   [OpenStruct.new(url: 'https://some-course.net',
                                                   title: 'Yet another course',
                                                   start: '2021-01-31 13:00:00',
                                                   end: '2021-01-31 14:00:00')])
    assert_difference('provider.events.count', 1) do
      ingestor.write(user, provider, source: @source)
    end
    event = Event.find_by(title: 'Yet another course')
    assert_nil(event.language)
  end

  def run_filter(source_filter)
    source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                            enabled: true, approval_status: 'approved',
                            content_provider: content_providers(:portal_provider), user: users(:admin),
                            source_filters: [source_filter])
    ingestor = Ingestors::Ingestor.new
    ingestor.instance_variable_set(:@events,
                                   [events(:passing_import_filters_event), events(:passing_contains_import_filters_event), events(:failing_import_filters_event)])
    ingestor.instance_variable_set(:@materials,
                                   [materials(:passing_import_filters_material), materials(:passing_contains_import_filters_material), materials(:failing_import_filters_material)])
    ingestor.filter(source)
    ingestor
  end

  test 'does respect material filter conditions' do
    [
      source_filters(:source_filter_target_audience),
      source_filters(:source_filter_keyword),
      source_filters(:source_filter_title),
      source_filters(:source_filter_description),
      source_filters(:source_filter_description_contains),
      source_filters(:source_filter_url),
      source_filters(:source_filter_url_prefix),
      source_filters(:source_filter_doi),
      source_filters(:source_filter_license),
      source_filters(:source_filter_difficulty_level),
      source_filters(:source_filter_resource_type),
      source_filters(:source_filter_prerequisites_contains),
      source_filters(:source_filter_learning_objectives_contains)
    ].each do |filter|
      filtered_ingestor = run_filter(filter)
      assert_includes(filtered_ingestor.instance_variable_get(:@materials), materials(:passing_import_filters_material), "Filter_by: #{filter.filter_by}")
      refute_includes(filtered_ingestor.instance_variable_get(:@materials), materials(:failing_import_filters_material), "Filter_by: #{filter.filter_by}")
    end
  end

  test 'does respect event only filter conditions' do
    [
      source_filters(:source_filter_subtitle_contains),
      source_filters(:source_filter_city),
      source_filters(:source_filter_country),
      source_filters(:source_filter_event_type),
      source_filters(:source_filter_timezone)
    ].each do |filter|
      filtered_ingestor = run_filter(filter)
      assert_includes(filtered_ingestor.instance_variable_get(:@events), events(:passing_import_filters_event), "Filter_by: #{filter.filter_by}")
      refute_includes(filtered_ingestor.instance_variable_get(:@events), events(:failing_import_filters_event), "Filter_by: #{filter.filter_by}")
    end
  end

  test 'does respect contains filter conditions' do
    [
      source_filters(:source_filter_url_prefix),
      source_filters(:source_filter_description_contains),
      source_filters(:source_filter_prerequisites_contains),
      source_filters(:source_filter_learning_objectives_contains)
    ].each do |filter|
      filtered_ingestor = run_filter(filter)
      assert_includes(filtered_ingestor.instance_variable_get(:@materials), materials(:passing_contains_import_filters_material), "Filter_by: #{filter.filter_by}")
    end

    [
      source_filters(:source_filter_subtitle_contains)
    ].each do |filter|
      filtered_ingestor = run_filter(filter)
      assert_includes(filtered_ingestor.instance_variable_get(:@events), events(:passing_contains_import_filters_event), "Filter_by: #{filter.filter_by}")
    end
  end

  test 'does respect block list filter' do
    filtered_ingestor = run_filter(source_filters(:source_filter_keyword_block))
    refute_includes(filtered_ingestor.instance_variable_get(:@materials), materials(:passing_import_filters_material))
    assert_includes(filtered_ingestor.instance_variable_get(:@materials), materials(:failing_import_filters_material))
  end
end
