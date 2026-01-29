require 'test_helper'

class IndicoIngestorTest < ActiveSupport::TestCase
  setup do
    @ingestor = Ingestors::IndicoIngestor.new
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    # mock_ingestions
    # mock_timezone # System time zone should not affect test result

    webmock('https://indico.cern.ch/event/1617123/', 'indico/indico.html')
    webmock('https://indico.cern.ch/event/1617123/event.ics', 'indico/event.ics')
    webmock('https://indico.cern.ch/category/11733/', 'indico/indico.html')
    webmock('https://indico.cern.ch/category/11733/events.ics', 'indico/events.ics')
    webmock('https://myagenda.com/event/1617123/', 'indico/indico.html')
    webmock('https://myagenda.com/event/1617123/event.ics', 'indico/event.ics')
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
    assert_equal sample.description, 'speakers and zoom here'
    assert_equal sample.keywords, %w[TRAINING EDUCATION]
    assert_equal sample.contact, 'name.surname@test.com'
    assert_equal sample.start, '2026-03-09 08:00:00 +0000'
    assert_equal sample.end, '2026-03-13 16:15:00 +0000'
    assert_equal sample.timezone, 'UTC'
    assert_equal sample.venue, 'CERN'
    assert_match sample.presence, 'hybrid'
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
    @ingestor.read('https://myagenda.com/event/1617123/')
    @ingestor.write(@user, @content_provider)

    sample = @ingestor.events.detect { |e| e.title == '14th HEP C++ Course and Hands-on Training - The Essentials' }
    assert sample.persisted?

    assert_equal sample.url, 'https://indico.cern.ch/event/1617123/'
  end

  test 'should convert url properly' do
    indico_url_event = 'https://indico.cern.ch/event/1588342/'
    indico_url_event_with_ics = 'https://indico.cern.ch/event/1588342/event.ics' # ! when '/event', event.ics is singular
    indico_url_event_with_query = 'https://indico.cern.ch/event/1588342/?somerandom=urlparams&an=otherone'
    indico_url_event_with_query_with_ics = 'https://indico.cern.ch/event/1588342/event.ics?somerandom=urlparams&an=otherone'
    indico_url_category = 'https://indico.cern.ch/category/19377/'
    indico_url_category_with_ics = 'https://indico.cern.ch/category/19377/events.ics' # ! when '/category', eventS.ics is plural
    indico_url_category_with_query = 'https://indico.cern.ch/category/19377/?a=b&c=d'
    indico_url_category_with_query_with_ics = 'https://indico.cern.ch/category/19377/events.ics?a=b&c=d'
    url_with_ics = 'https://mywebsite.com/event/blabla/event.ics'
    url_with_query_with_ics = 'https://mywebsite.com/event/blabla/event.ics?john=doe&isstub=born'

    # When indico link – event
    assert_equal @ingestor.send(:to_export, indico_url_event), indico_url_event_with_ics # adds event.ics
    assert_equal @ingestor.send(:to_export, indico_url_event_with_query), indico_url_event_with_query_with_ics # adds event.ics

    # When indico link – category
    assert_equal @ingestor.send(:to_export, indico_url_category), indico_url_category_with_ics # adds events.ics (with an s)
    assert_equal @ingestor.send(:to_export, indico_url_category_with_query), indico_url_category_with_query_with_ics # adds events.ics (with an s)

    # When non-indico but ics link
    assert_equal @ingestor.send(:to_export, url_with_ics), url_with_ics # keeps same
    assert_equal @ingestor.send(:to_export, url_with_query_with_ics), url_with_query_with_ics # keeps same

    # When indico link which already has the /events.ics
    assert_equal @ingestor.send(:to_export, indico_url_event_with_ics), indico_url_event_with_ics # keeps it as-is
    assert_equal @ingestor.send(:to_export, indico_url_event_with_query_with_ics), indico_url_event_with_query_with_ics # keeps it as-is
  end

  test 'should test std err' do
    @ingestor.stub :open_url, ->(_url, *) { raise StandardError, 'test failure' } do
      @ingestor.send(:process_url, 'https://indico.cern.ch/event/1617123/')

      assert_equal 'Process file url[https://indico.cern.ch/event/1617123/event.ics] failed with: test failure', @ingestor.messages.first
    end

    @ingestor.stub(:assign_basic_info, ->(*) { raise StandardError, 'test failure' }) do
      mock_logger = Minitest::Mock.new
      mock_logger.expect(:error, nil, ['StandardError: test failure'])

      Rails.stub(:logger, mock_logger) do
        @ingestor.send(:process_calevent, Icalendar::Event.new)
      end
      mock_logger.verify
    end
  end

  private

  def webmock(url, filename)
    file = Rails.root.join('test', 'fixtures', 'files', 'ingestion', filename)
    WebMock.stub_request(:get, url).to_return(status: 200, headers: {}, body: file.read)
  end
end
