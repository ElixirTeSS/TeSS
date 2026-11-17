require 'test_helper'

class IndicoIngestorTest < ActiveSupport::TestCase
  setup do
    @ingestor = Ingestors::IndicoIngestor.new
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    # mock_ingestions
    # mock_timezone # System time zone should not affect test result

    webmock('https://indico.cern.ch/event/1617123/', 'indico/indico.html')
    webmock('https://indico.cern.ch/event/1617123/events.ics?nc=yes', 'indico/event.ics')
    webmock('https://indico.cern.ch/category/11733/', 'indico/indico.html')
    webmock('https://indico.cern.ch/export/categ/11733.ics?from=1900-01-01&to=2100-12-31&nc=yes', 'indico/events.ics')
    webmock('https://myagenda.com/event/1617123/', 'indico/indico.html')
    webmock('https://myagenda.com/event/1617123/event.ics?nc=yes', 'indico/event.ics')
  end

  teardown do
    reset_timezone
  end

  test 'should read indico link event' do
    @ingestor.read('https://indico.cern.ch/event/1617123/')
    @ingestor.write(@user, @content_provider)

    sample = @ingestor.events.detect { |e| e.title == '14th HEP C++ Course and Hands-on Training - The Essentials' }
    assert sample.persisted?

    assert_equal sample.url, 'https://indico.cern.ch/event/1617123/'
    assert_equal sample.title, '14th HEP C++ Course and Hands-on Training - The Essentials'
    assert_equal sample.description, 'speakers and Zoom here, however it is not hybrid'
    assert_equal sample.keywords, %w[TRAINING EDUCATION]
    assert_equal sample.contact, 'name.surname@test.com'
    assert_equal sample.start, '2026-03-09 08:00:00 +0000'
    assert_equal sample.end, '2026-03-13 16:15:00 +0000'
    assert_equal sample.timezone, 'UTC'
    assert_equal sample.venue, 'CERN'
    assert_match sample.presence, 'online'
  end

  test 'should read indico link category' do
    @ingestor.read('https://indico.cern.ch/category/11733/')
    @ingestor.write(@user, @content_provider)

    sample = @ingestor.events.detect { |e| e.title == '14th HEP C++ Course and Hands-on Training - The Essentials' }
    sample2 = @ingestor.events.detect { |e| e.title == 'HEP C++ Course and Hands-on Training - Stay Informed' }
    assert sample.persisted?
    assert sample2.persisted?

    assert_equal sample.url, 'https://indico.cern.ch/event/1617123/'
    assert_equal sample2.url, 'https://indico.cern.ch/event/1211412/'
  end

  test 'should read non-indico link event' do
    @ingestor.read('https://myagenda.com/event/1617123/event.ics')
    @ingestor.write(@user, @content_provider)

    sample = @ingestor.events.detect { |e| e.title == '14th HEP C++ Course and Hands-on Training - The Essentials' }
    assert sample.persisted?

    assert_equal sample.url, 'https://indico.cern.ch/event/1617123/'
  end

  test 'should convert url properly' do
    indico_url_event = 'https://indico.cern.ch/event/1588342/'
    indico_url_event_with_ics = 'https://indico.cern.ch/event/1588342/event.ics'
    indico_url_event_with_events_ics = 'https://indico.cern.ch/event/1588342/events.ics'
    indico_url_event_with_query = 'https://indico.cern.ch/event/1588342/?somerandom=urlparams&an=otherone'
    indico_url_event_with_query_with_ics = 'https://indico.cern.ch/event/1588342/event.ics?somerandom=urlparams&an=otherone'
    indico_url_event_with_events_ics_and_query = 'https://indico.cern.ch/event/1588342/events.ics?somerandom=urlparams&an=otherone'
    indico_url_category = 'https://indico.cern.ch/category/19377/'
    indico_url_category_with_ics = 'https://indico.cern.ch/export/categ/19377.ics?from=1900-01-01&to=2100-12-31&nc=yes'
    indico_url_category_with_query = 'https://indico.cern.ch/category/19377/?a=b&c=d'
    indico_url_category_with_query_with_ics = 'https://indico.cern.ch/export/categ/19377.ics?a=b&c=d&from=1900-01-01&to=2100-12-31&nc=yes'
    url_with_ics = 'https://mywebsite.com/event/blabla/event.ics'
    url_with_query_with_ics = 'https://mywebsite.com/event/blabla/event.ics?john=doe&isstub=born'

    # When indico link – event
    assert_equal indico_url_event_with_events_ics, @ingestor.send(:to_export, indico_url_event)
    assert_equal indico_url_event_with_events_ics_and_query, @ingestor.send(:to_export, indico_url_event_with_query)

    # When indico link – category
    assert_equal indico_url_category_with_ics, @ingestor.send(:to_export, indico_url_category)
    assert_equal indico_url_category_with_query_with_ics, @ingestor.send(:to_export, indico_url_category_with_query)

    # When non-indico but ics link
    assert_equal @ingestor.send(:to_export, url_with_ics), url_with_ics # keeps same
    assert_equal @ingestor.send(:to_export, url_with_query_with_ics), url_with_query_with_ics # keeps same

    # When indico link which already has the /events.ics
    assert_equal @ingestor.send(:to_export, indico_url_event_with_ics), indico_url_event_with_ics # keeps it as-is
    assert_equal @ingestor.send(:to_export, indico_url_event_with_query_with_ics), indico_url_event_with_query_with_ics # keeps it as-is
  end

  test 'should test std err' do
    @ingestor.stub :fetch_calendar_content, ->(_url) { raise StandardError, 'test failure' } do
      @ingestor.read('https://indico.cern.ch/event/1617123/')

      assert_equal 'Process file URL [https://indico.cern.ch/event/1617123/] failed with: test failure', @ingestor.messages.first
    end

    calendar = Rails.root.join('test/fixtures/files/ingestion/indico/event.ics').read
    @ingestor.stub(:fetch_calendar_content, calendar) do
      @ingestor.stub(:process_calevent, ->(_event) { raise StandardError, 'test failure' }) do
        @ingestor.read('https://indico.cern.ch/event/1617123/')
      end
    end

    assert_includes @ingestor.messages, 'Failed to process Indico event indico-event-1617123@indico.cern.ch: test failure'
  end

  private

  def webmock(url, filename)
    file = Rails.root.join('test', 'fixtures', 'files', 'ingestion', filename)
    WebMock.stub_request(:get, url).to_return(status: 200, headers: {}, body: file.read)
  end
end
