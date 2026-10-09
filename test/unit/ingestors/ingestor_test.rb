require 'test_helper'

class IngestorTest < ActiveSupport::TestCase
  test 'ingestors always have distinct unsaved Sources and reject invalid replacements' do
    ingestor = Ingestors::Ingestor.new
    other = Ingestors::IngestorFactory.get_ingestor(Source.new(method: 'event_rss'))

    assert_instance_of Source, ingestor.source
    assert_instance_of Source, other.source
    assert ingestor.source.new_record?
    refute_same ingestor.source, other.source
    assert_equal '', ingestor.token
    assert_nil ingestor.source_host

    [nil, 'not a Source'].each do |invalid|
      assert_raises(ArgumentError) { ingestor.source = invalid }
      assert_instance_of Source, ingestor.source
    end
  end

  test 'factory requires a Source and assigns its context without saving it' do
    source = Source.new(method: 'event_rss', url: 'https://registry.example.org/feed', token: 'source-token',
                        content_provider: content_providers(:portal_provider))
    ingestor = nil

    assert_no_difference('Source.count') do
      ingestor = Ingestors::IngestorFactory.get_ingestor(source)
    end

    assert_instance_of Ingestors::EventRSSIngestor, ingestor
    assert_same source, ingestor.source
    assert_equal 'source-token', ingestor.token
    assert_equal 'registry.example.org', ingestor.source_host
    assert source.new_record?

    assert_raises(ArgumentError) { Ingestors::IngestorFactory.get_ingestor }
    [nil, 'event_rss'].each do |invalid|
      assert_raises(ArgumentError) { Ingestors::IngestorFactory.get_ingestor(invalid) }
    end
    error = assert_raises(RuntimeError) do
      Ingestors::IngestorFactory.get_ingestor(Source.new(method: 'not-a-method'))
    end
    assert_equal 'Invalid method: [not-a-method]', error.message
  end

  test 'Source ingestor lookup returns an ingestor with that same Source' do
    source = sources(:first_source)
    ingestor = source.ingestor_class

    assert_same source, ingestor.source
    assert_equal source.method, ingestor.config[:key]
    assert_equal ingestor.config[:title], source.ingestor_title
  end

  test 'source assignment provides tokens to legacy ingestors and does not cache the hostname' do
    ingestor = Ingestors::Ingestor.new
    source = Source.new(url: 'https://registry.example.org/sitemap.txt', token: 'source-token')
    ingestor.source = source

    assert_same source, ingestor.source
    assert_equal 'source-token', ingestor.token
    assert_equal 'source-token', ingestor.instance_variable_get(:@token)
    assert_equal 'registry.example.org', ingestor.source_host

    source.url = 'https://another.example.org'
    assert_equal 'another.example.org', ingestor.source_host

    ingestor.source = Source.new
    assert_equal '', ingestor.token
    assert_nil ingestor.source_host
    ingestor.token = 'legacy-override'
    assert_equal 'legacy-override', ingestor.token
  end

  test 'unsaved source supplies provider filters and defaults without being saved or logged as a persisted source' do
    ingestor = Ingestors::Ingestor.new
    provider = content_providers(:organisation_provider)
    source = Source.new(url: 'https://registry.example.org', method: 'bioschemas',
                        content_provider: provider, default_language: 'fr', space: spaces(:plants),
                        source_filters: [SourceFilter.new(mode: 'block', property: 'title', value: 'Blocked')])
    ingestor.source = source
    ingestor.add_event(title: 'Imported event', description: 'Training', url: 'https://event.example.org',
                       start: 1.day.from_now, end: 2.days.from_now)
    ingestor.add_event(title: 'Blocked', description: 'Training', url: 'https://event.example.org/blocked')

    source.stub(:valid?, -> { flunk 'An unsaved ingestion Source must not be validated' }) do
      assert_no_difference('Source.count') do
        assert_difference('Event.count') { ingestor.write(users(:scraper_user)) }
      end
    end

    assert source.new_record?
    assert_equal 1, ingestor.events.size
    event = ingestor.events.first
    assert_equal provider, event.content_provider
    assert_equal 'fr', event.language
    assert_equal spaces(:plants), event.space
    refute event.activities.find_by!(key: 'event.create').parameters.key?(:source)
  end

  test 'write uses the assigned source provider and never saves an unsaved Source' do
    ingestor = Ingestors::Ingestor.new
    provider = content_providers(:organisation_provider)
    ingestor.source = Source.new(method: 'bioschemas', content_provider: provider)
    ingestor.add_material(title: 'Legacy material', description: 'Training', url: 'https://material.example.org/legacy')

    assert_no_difference('Source.count') do
      assert_difference('Material.count') { ingestor.write(users(:scraper_user)) }
    end
    assert ingestor.source.new_record?
    material = ingestor.materials.first
    assert_equal provider, material.content_provider
    refute material.activities.find_by!(key: 'material.create').parameters.key?(:source)
  end

  test 'write rejects missing provider context before persisting anything' do
    ingestor = Ingestors::Ingestor.new
    ingestor.add_material(title: 'Unattributed', description: 'Training', url: 'https://material.example.org/unattributed')

    assert_no_difference('Material.count') do
      assert_raises(ArgumentError) { ingestor.write(users(:scraper_user)) }
    end
  end

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
    ingestor.source = @source

    # Fake an event that was read ... no language set
    ingestor.instance_variable_set(:@events,
                                   [OpenStruct.new(url: 'https://some-course.ca',
                                                   title: 'Some course',
                                                   start: '2021-01-31 13:00:00',
                                                   end: '2021-01-31 14:00:00')])
    assert_difference('provider.events.count', 1) do
      ingestor.write(user)
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
    ingestor.source = @source

    # Fake an event that was read ... with language set
    ingestor.instance_variable_set(:@events,
                                   [OpenStruct.new(url: 'https://some-course.de',
                                                   title: 'Some german course',
                                                   start: '2021-01-31 13:00:00',
                                                   end: '2021-01-31 14:00:00',
                                                   language: 'de')])
    assert_difference('provider.events.count', 1) do
      ingestor.write(user)
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
    ingestor.source = @source

    # Fake an event that was read ... with language set
    ingestor.instance_variable_set(:@events,
                                   [OpenStruct.new(url: 'https://some-course.org',
                                                   title: 'Some other course',
                                                   start: '2021-01-31 13:00:00',
                                                   end: '2021-01-31 14:00:00',
                                                   language: 'de')])
    assert_difference('provider.events.count', 1) do
      ingestor.write(user)
    end
    event = Event.find_by(title: 'Some other course')
    assert_equal(event.language, 'de')
  end

  ['enabled', 'disabled'].each do |enabled|
    test "auto parse if #{enabled}" do
      if enabled == 'enabled'
        auto_parse_vars = ['target_audience', 'keywords']
      else
        auto_parse_vars = []
      end
      user = users(:scraper_user)
      provider = content_providers(:portal_provider)
      @source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                              enabled: true, approval_status: 'approved',
                              content_provider: provider, user: users(:admin))
      ingestor = Ingestors::Ingestor.new
      ingestor.source = @source
      new_event = OpenStruct.new(url: 'https://some-course.net',
                                  title: 'Yet another event',
                                  start: '2021-01-31 13:00:00',
                                  end:'2021-01-31 14:00:00',
                                  description: 'professor, tool criticism and software citation in text')
      new_material = OpenStruct.new(url: 'https://some-course.net',
                                  title: 'Yet another course',
                                  description: 'professor, tool criticism and software citation in text')
      with_settings({ feature: { auto_parse_vars: auto_parse_vars } }) do
        ingestor.add_event(new_event)
        ingestor.add_material(new_material)
        assert_difference('provider.events.count', 1) do
          assert_difference('provider.materials.count', 1) do
            ingestor.write(user)
          end
        end
      end
      event = Event.find_by(title: 'Yet another event')
      material = Material.find_by(title: 'Yet another course')
      [event, material].each do |obj|
        if enabled == 'enabled'
          assert_equal(['researchers'].sort, obj.target_audience.sort)
          assert_equal(['Research software management', 'Data infrastructure'].sort, obj.keywords.sort)
        else
          assert_equal([], obj.target_audience)
          assert_equal([], obj.keywords)
        end
      end
    end

    test "handle controlled vocabulary if #{enabled}" do
      if enabled == 'enabled'
        controlled_vocabulary = ['target_audience', 'keywords']
      else
        controlled_vocabulary = []
      end
      user = users(:scraper_user)
      provider = content_providers(:portal_provider)
      @source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                              enabled: true, approval_status: 'approved',
                              content_provider: provider, user: users(:admin))
      ingestor = Ingestors::Ingestor.new
      ingestor.source = @source
      new_event = OpenStruct.new(url: 'https://some-course.net',
                                  title: 'Yet another event',
                                  start: '2021-01-31 13:00:00',
                                  end:'2021-01-31 14:00:00',
                                  description: 'professor, tool criticism and software citation in text',
                                  target_audience: ['nonsense', 'students', 'github beginners'],
                                  keywords: ['nonsense', 'data infrastructure', 'Policy development'])
      new_material = OpenStruct.new(url: 'https://some-course.net',
                                  title: 'Yet another course',
                                  description: 'professor, tool criticism and software citation in text',
                                  target_audience: ['nonsense', 'students', 'github beginners'],
                                  keywords: ['nonsense', 'data infrastructure', 'Policy development'])
      with_settings({ feature: { controlled_vocabulary_vars: controlled_vocabulary } }) do
        ingestor.add_event(new_event)
        ingestor.add_material(new_material)
        assert_difference('provider.events.count', 1) do
          assert_difference('provider.materials.count', 1) do
            ingestor.write(user)
          end
        end
      end
      event = Event.find_by(title: 'Yet another event')
      material = Material.find_by(title: 'Yet another course')
      [event, material].each do |obj|
        if enabled == 'enabled'
          assert_equal(['students', 'other'].sort, obj.target_audience.sort)
          assert_equal(['Data infrastructure', 'Policy and governance'].sort, obj.keywords.sort)
        else
          assert_equal(['nonsense', 'students', 'github beginners'], obj.target_audience)
          assert_equal(['nonsense', 'data infrastructure', 'Policy development'], obj.keywords)
        end
      end
    end
  end

  test 'does not set event language when language and source default language missing' do
    user = users(:scraper_user)
    provider = content_providers(:portal_provider)

    # Source has no default language set
    @source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                             enabled: true, approval_status: 'approved',
                             content_provider: provider, user: users(:admin))

    ingestor = Ingestors::Ingestor.new
    ingestor.source = @source

    # Fake an event that was read ... no language set
    ingestor.instance_variable_set(:@events,
                                   [OpenStruct.new(url: 'https://some-course.net',
                                                   title: 'Yet another course',
                                                   start: '2021-01-31 13:00:00',
                                                   end: '2021-01-31 14:00:00')])
    assert_difference('provider.events.count', 1) do
      ingestor.write(user)
    end
    event = Event.find_by(title: 'Yet another course')
    assert_nil(event.language)
  end

  test 'sets last_scraped_by_id for scrapable resources when source is provided' do
    user = users(:scraper_user)
    source = sources(:first_source)
    provider = source.content_provider

    ingestor = Ingestors::Ingestor.new
    ingestor.instance_variable_set(:@events,
                                   [OpenStruct.new(url: 'https://example.org/scraped-event',
                                                   title: 'Scraped Event',
                                                   start: '2021-01-31 13:00:00',
                                                   end: '2021-01-31 14:00:00')])
    ingestor.instance_variable_set(:@materials,
                                   [OpenStruct.new(url: 'https://example.org/scraped-material',
                                                   title: 'Scraped Material',
                                                   description: 'A scraped material')])

    ingestor.source = source
    ingestor.write(user)

    event = Event.find_by(url: 'https://example.org/scraped-event')
    material = Material.find_by(url: 'https://example.org/scraped-material')

    assert_equal source, event.last_scraped_by_source
    assert_equal source, material.last_scraped_by_source
  end

  def build_ingested_event(existing_event, extra_attrs: {})
    OpenStruct.new({
      url: existing_event.url,
      title: existing_event.title,
      start: existing_event.start,
      end: existing_event.end,
      description: existing_event.description
    }.merge(extra_attrs))
  end

  test 'switches responsibility when new resource has more considered metadata fields' do
    user = users(:scraper_user)
    source = sources(:first_source)
    provider = source.content_provider

    event = events(:responsibility_candidate_event)

    ingestor = Ingestors::Ingestor.new
    ingestor.instance_variable_set(:@events,
                                   [build_ingested_event(event,
                                                         extra_attrs: {venue: 'Main Hall'}
                                                        )
                                   ])

    assert_no_difference('provider.events.count') do
      ingestor.source = source
      ingestor.write(user)
    end

    event.reload
    assert_equal source, event.last_scraped_by_source
    assert_equal 'Main Hall', event.venue
  end

  test 'switches responsibility when considered field count is equal but description content is much longer' do
    user = users(:scraper_user)
    source = sources(:first_source)
    provider = source.content_provider

    event = events(:responsibility_candidate_event)

    ingestor = Ingestors::Ingestor.new
    ingestor.instance_variable_set(:@events,
                                   [build_ingested_event(event,
                                                         extra_attrs: {
                                                           description: "#{'long description ' * 12}with more detail"
                                                         })])

    assert_no_difference('provider.events.count') do
      ingestor.source = source
      ingestor.write(user)
    end

    event.reload
    assert_equal source, event.last_scraped_by_source
  end

  test 'does not switch responsibility when new resource is not richer by considered fields or description' do
    user = users(:scraper_user)
    source = sources(:first_source)
    provider = source.content_provider

    event = events(:responsibility_candidate_event)

    ingestor = Ingestors::Ingestor.new
    ingestor.instance_variable_set(:@events, [build_ingested_event(event)])

    assert_no_difference('provider.events.count') do
      ingestor.source = source
      ingestor.write(user)
    end

    event.reload
    assert_equal sources(:second_source), event.last_scraped_by_source
  end

  test 'claims responsibility for legacy records without a last scraped source' do
    user = users(:scraper_user)
    source = sources(:first_source)
    provider = source.content_provider

    event = events(:responsibility_candidate_event)
    event.update_column(:last_scraped_by_id, nil)

    ingestor = Ingestors::Ingestor.new
    ingestor.instance_variable_set(:@events, [build_ingested_event(event)])

    assert_no_difference('provider.events.count') do
      ingestor.source = source
      ingestor.write(user)
    end

    event.reload
    assert_equal source, event.last_scraped_by_source
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
    ingestor.source = source
    ingestor.filter
    ingestor
  end

  test 'does respect material filter conditions' do
    [
      source_filters(:source_filter_target_audience),
      source_filters(:source_filter_keyword),
      source_filters(:source_filter_title),
      source_filters(:source_filter_title_contains),
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
      assert_includes(filtered_ingestor.instance_variable_get(:@materials), materials(:passing_import_filters_material), "property: #{filter.property}")
      refute_includes(filtered_ingestor.instance_variable_get(:@materials), materials(:failing_import_filters_material), "property: #{filter.property}")
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
      assert_includes(filtered_ingestor.instance_variable_get(:@events), events(:passing_import_filters_event), "property: #{filter.property}")
      refute_includes(filtered_ingestor.instance_variable_get(:@events), events(:failing_import_filters_event), "property: #{filter.property}")
    end
  end

  test 'does respect contains filter conditions' do
    [
      source_filters(:source_filter_url_prefix),
      source_filters(:source_filter_title_contains),
      source_filters(:source_filter_description_contains),
      source_filters(:source_filter_prerequisites_contains),
      source_filters(:source_filter_learning_objectives_contains)
    ].each do |filter|
      filtered_ingestor = run_filter(filter)
      assert_includes(filtered_ingestor.instance_variable_get(:@materials), materials(:passing_contains_import_filters_material), "property: #{filter.property}")
    end

    [
      source_filters(:source_filter_subtitle_contains)
    ].each do |filter|
      filtered_ingestor = run_filter(filter)
      assert_includes(filtered_ingestor.instance_variable_get(:@events), events(:passing_contains_import_filters_event), "property: #{filter.property}")
    end
  end

  test 'every condition must be met in allowlist' do
    source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                            enabled: true, approval_status: 'approved',
                            content_provider: content_providers(:portal_provider), user: users(:admin),
                            source_filters: [source_filters(:source_filter_keyword), source_filters(:source_filter_allow_shared_keyword)])
    ingestor = Ingestors::Ingestor.new
    ingestor.instance_variable_set(:@materials,
                                   [materials(:passing_import_filters_material), materials(:failing_import_filters_material)])
    ingestor.source = source
    ingestor.filter
    
    assert_includes(ingestor.instance_variable_get(:@materials), materials(:passing_import_filters_material))
    refute_includes(ingestor.instance_variable_get(:@materials), materials(:failing_import_filters_material))
  end

  test 'any filter sufficient in block list' do
    source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                            enabled: true, approval_status: 'approved',
                            content_provider: content_providers(:portal_provider), user: users(:admin),
                            source_filters: [source_filters(:source_filter_keyword_block), source_filters(:source_filter_block_unused_keyword)])
    ingestor = Ingestors::Ingestor.new
    ingestor.instance_variable_set(:@materials,
                                   [materials(:passing_import_filters_material), materials(:failing_import_filters_material)])
    ingestor.source = source
    ingestor.filter
    
    refute_includes(ingestor.instance_variable_get(:@materials), materials(:passing_import_filters_material))
    assert_includes(ingestor.instance_variable_get(:@materials), materials(:failing_import_filters_material))
  end

  test 'does respect block list filter' do
    filtered_ingestor = run_filter(source_filters(:source_filter_keyword_block))
    refute_includes(filtered_ingestor.instance_variable_get(:@materials), materials(:passing_import_filters_material))
    assert_includes(filtered_ingestor.instance_variable_get(:@materials), materials(:failing_import_filters_material))
  end

  test 'open_url returns content when URL is valid' do
    ingestor = DummyIngestor.new
    stub_request(:get, 'https://example.com').to_return(body: 'ok', status: 200)

    result = ingestor.open_url('https://example.com')
    assert_equal 'ok', result.read
  end

  test 'open_url raises exception after too many redirects' do
    ingestor = DummyIngestor.new
    WebMock.stub_request(:any, 'https://redirect.loop/').to_return(status: 301,
                                                                   headers: { 'Location' => 'https://redirect.loop/' })

    assert_raises(OpenURI::HTTPRedirect) do
      ingestor.open_url('https://redirect.loop/')
    end
  end

  test 'open_url logs error status' do
    ingestor = DummyIngestor.new
    WebMock.stub_request(:any, 'https://bad.com/').to_return(status: 404)

    result = ingestor.open_url('https://bad.com')
    assert_nil result
    assert_includes ingestor.instance_variable_get(:@messages).last,
                    "Couldn't open URL https://bad.com: 404"
  end

  test 'get_redirected_url follows meta refresh redirect' do
    ingestor = DummyIngestor.new
    html_with_meta = '<html><head><meta http-equiv="Refresh" content="0; url=/redirected"></head></html>'
    redirected_html = '<html><head><title>Final</title></head><body>Done</body></html>'

    HTTParty.stub(:get, lambda { |url, **|
      case url
      when 'https://example.com/'
        OpenStruct.new(headers: { 'content-type' => 'text/html' }, body: html_with_meta)
      when 'https://example.com//redirected'
        OpenStruct.new(headers: { 'content-type' => 'text/html' }, body: redirected_html)
      else
        raise "Unexpected URL: #{url}"
      end
    }) do
      result = ingestor.get_redirected_url('http://example.com/')
      assert_equal 'https://example.com//redirected', result
    end
  end

  test 'get_redirected_url returns original url when no meta redirect' do
    ingestor = DummyIngestor.new
    html_no_meta = '<html><head><title>No redirect</title></head><body></body></html>'

    HTTParty.stub(:get, ->(_url, **) { OpenStruct.new(headers: { 'content-type' => 'text/html' }, body: html_no_meta) }) do
      result = ingestor.get_redirected_url('http://example.com/')
      assert_equal 'https://example.com/', result
    end
  end

  test 'get_redirected_url raises when too many redirects' do
    ingestor = DummyIngestor.new
    html_with_meta = '<html><head><meta http-equiv="Refresh" content="0; url=/loop"></head></html>'

    HTTParty.stub(:get, ->(_url, **) { OpenStruct.new(headers: { 'content-type' => 'text/html' }, body: html_with_meta) }) do
      assert_raises(RuntimeError, 'Too many redirects') do
        ingestor.get_redirected_url('http://example.com/', 0)
      end
    end
  end

  test 'sets event space from source space' do
    user = users(:scraper_user)
    provider = content_providers(:portal_provider)
    space = spaces(:plants)

    @source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                             enabled: true, approval_status: 'approved',
                             space: space, content_provider: provider, user: users(:admin))

    ingestor = Ingestors::Ingestor.new
    ingestor.source = @source

    ingestor.instance_variable_set(:@events,
                                   [OpenStruct.new(url: 'https://some-course.ca',
                                                   title: 'Some course',
                                                   start: '2021-01-31 13:00:00',
                                                   end: '2021-01-31 14:00:00')])
    assert_difference('provider.events.count', 1) do
      ingestor.write(user)
    end
    event = Event.find_by(title: 'Some course')
    assert_equal space, event.space
  end

  test 'handles HTTP errors and SSRF attempts' do
    WebMock.stub_request(:any, 'http://200host.com').to_return(status: 200, body: 'hi')
    WebMock.stub_request(:any, 'http://404host.com').to_return(status: 404, body: 'hi')
    WebMock.stub_request(:any, 'http://slowhost.com').to_timeout

    ingestor = Ingestors::BioschemasIngestor.new

    # 200
    assert ingestor.open_url('http://200host.com')

    # 404
    assert_nil ingestor.open_url('http://404host.com')
    assert_equal "Couldn't open URL http://404host.com: 404 ", ingestor.messages.last
    assert_raises(OpenURI::HTTPError) do
      ingestor.open_url('http://404host.com', raise: true)
    end

    # private address
    begin
      server = TCPServer.new(3005)
      thread = Thread.start { server.accept }
      with_net_connection do # Allow request through to be caught by private_address_check
        assert_nil ingestor.open_url('http://localhost:3005')
        assert_equal "Couldn't open URL http://localhost:3005", ingestor.messages.last
        assert_raises(RuntimeError) do
          ingestor.open_url('http://localhost:3005', raise: true)
        end
      end
    ensure
      thread.exit if thread
    end

    # timeout
    assert_raises(Net::OpenTimeout) do
      ingestor.open_url('http://slowhost.com') # Always raises
    end
  end

  test 'does not log useless update activities' do
    user = users(:scraper_user)
    provider = content_providers(:goblet)
    url = 'http://example.com/cool-course-summer'
    e = events(:course_event)
    e.update!(scraper_record: true)

    assert provider.events.where(url: url).any?

    event = OpenStruct.new(url: 'http://example.com/cool-course-summer', title: 'A different title')

    ingestor = Ingestors::Ingestor.new
    ingestor.source = Source.new(method: 'bioschemas', content_provider: provider)
    ingestor.instance_variable_set(:@events, [event])
    assert_no_difference('provider.events.count') do
      assert_no_difference('PublicActivity::Activity.where(key: "event.create").count') do
        assert_difference('PublicActivity::Activity.where(key: "event.update").count', 1) do
          assert_difference('PublicActivity::Activity.where(key: "event.update_parameter").count', 1) do # Title is changed
            ingestor.write(user)
          end
        end
      end
    end

    ingestor = Ingestors::Ingestor.new
    ingestor.source = Source.new(method: 'bioschemas', content_provider: provider)
    ingestor.instance_variable_set(:@events, [event])
    assert_no_difference('provider.events.count') do
      assert_no_difference('PublicActivity::Activity.where(key: "event.create").count') do
        assert_no_difference('PublicActivity::Activity.where(key: "event.update").count') do
          assert_no_difference('PublicActivity::Activity.where(key: "event.update_parameter").count') do
            ingestor.write(user) # Nothing changed so don't log
          end
        end
      end
    end
  end

end
