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
                                                   end:'2021-01-31 14:00:00')])
    assert_difference('provider.events.count', 1) do
      ingestor.write(user, provider, source: @source)
    end
    event = Event.find_by(title: 'Yet another course')
    assert_nil(event.language)
  end

  test 'open_url returns content when URL is valid' do
    ingestor = DummyIngestor.new
    stub_request(:get, 'https://example.com').to_return(body: 'ok', status: 200)

    result = ingestor.open_url('https://example.com')
    assert_equal 'ok', result.read
  end

  test 'open_url raises HTTPRedirect after too many retries' do
    ingestor = DummyIngestor.new
    fake_uri = URI('https://example.com/')

    URI.stub(:parse, fake_uri) do
      fake_uri.define_singleton_method(:open) do |*_args|
        raise OpenURI::HTTPRedirect.new('Redirect', 1, URI('https://redirected.com'))
      end

      assert_raises(OpenURI::HTTPRedirect) do
        ingestor.open_url('https://example.com/')
      end
    end
  end

  test 'open_url raises HTTPError' do
    ingestor = DummyIngestor.new
    stub_request(:get, 'https://bad.com')
      .to_raise(OpenURI::HTTPError.new('404 not found', StringIO.new))

    result = ingestor.open_url('https://bad.com')
    assert_nil result
    assert_includes ingestor.instance_variable_get(:@messages).last,
                    "Couldn't open URL https://bad.com: 404 not found"
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
end
