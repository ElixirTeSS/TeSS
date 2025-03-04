require 'test_helper'

class IngestorTest < ActiveSupport::TestCase
  test 'convert HTML descriptions to markdown where appropriate' do
    ingestor = Ingestors::Ingestor.new

    input = "### Title\n\nAmpersands & Quotes \""
    expected = input
    assert_equal expected, ingestor.convert_description(input)

    input = "<h1>Title</h1><ul><li>Item 1</li><li>Item 2</li>"
    expected = "# Title\n\n- Item 1\n- Item 2"
    assert_equal expected, ingestor.convert_description(input)
  end

  test 'sets event language from source default language' do
    user = users(:scraper_user)
    provider = content_providers(:portal_provider)
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
                                                   end:'2021-01-31 14:00:00')])
    assert_difference('provider.events.count', 1) do
      ingestor.write(user, provider, source: @source)
    end
    event = Event.find_by(title: 'Some course')
    assert_equal(event.language, 'fr')
  end

  test 'does not override event language from source default language when language set' do
    user = users(:scraper_user)
    provider = content_providers(:portal_provider)
    @source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                             enabled: true, approval_status: 'approved',
                             default_language: 'fr',
                             content_provider: provider, user: users(:admin))

    ingestor = Ingestors::Ingestor.new

    # Fake an event that was read ... no language set
    ingestor.instance_variable_set(:@events,
                                   [OpenStruct.new(url: 'https://some-course.de',
                                                   title: 'Some german course',
                                                   start: '2021-01-31 13:00:00',
                                                   end:'2021-01-31 14:00:00',
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
    @source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                             enabled: true, approval_status: 'approved',
                             content_provider: provider, user: users(:admin))

    ingestor = Ingestors::Ingestor.new

    # Fake an event that was read ... no language set
    ingestor.instance_variable_set(:@events,
                                   [OpenStruct.new(url: 'https://some-course.org',
                                                   title: 'Some other course',
                                                   start: '2021-01-31 13:00:00',
                                                   end:'2021-01-31 14:00:00',
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
    @source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                             enabled: true, approval_status: 'approved',
                             content_provider: provider, user: users(:admin))

    ingestor = Ingestors::Ingestor.new

    # Fake an event that was read ... no language set
    ingestor.instance_variable_set(:@events,
                                   [OpenStruct.new(url: 'https://some-course.net',
                                                   title: 'Yet another course',
                                                   start: '2021-01-31 13:00:00',
                                                   end:'2021-01-31 14:00:00')])
    assert_difference('provider.events.count', 1) do
      ingestor.write(user, provider, source: @source)
    end
    event = Event.find_by(title: 'Yet another course')
    assert_nil(event.language)
  end

end
