require 'test_helper'

class GrayScottIngestorTest < ActiveSupport::TestCase
  setup do
    @ingestor = Ingestors::Heptraining::GrayScottIngestor.new
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)

    webmock('https://cta-lapp.pages.in2p3.fr/COURS/GRAY_SCOTT_REVOLUTIONS/GrayScott2026/invitation/gray_scott_2026_webinars.ics', 'heptraining/grayscott/grayscott-event.ics')
    webmock('https://cta-lapp.pages.in2p3.fr/cours/gray_scott_revolutions/grayscott2026/redirect.html?label=sec_gray_scott_webinar_memory_allocation_memory_profiling', 'heptraining/grayscott/grayscott-redirect.html')
    webmock('https://cta-lapp.pages.in2p3.fr/cours/gray_scott_revolutions/grayscott2026/1-1-5-1-449.html', 'heptraining/grayscott/grayscott-page.html')
  end

  teardown do
    reset_timezone
  end

  test 'should read Gray Scott ics' do
    @ingestor.read('https://cta-lapp.pages.in2p3.fr/COURS/GRAY_SCOTT_REVOLUTIONS/GrayScott2026/invitation/gray_scott_2026_webinars.ics')
    @ingestor.write(@user, @content_provider)

    sample = @ingestor.events.detect { |e| e.title == 'Memory allocation, why and how to profile applications' }
    assert sample.persisted?

    assert_equal sample.url, 'https://cta-lapp.pages.in2p3.fr/cours/gray_scott_revolutions/grayscott2026/redirect.html?label=sec_gray_scott_webinar_memory_allocation_memory_profiling'
    assert_includes sample.description, 'Sometimes memory has become a major problem in applications'
    # DTSTART;TZID=Europe/Paris:20260226T100000, DTEND;TZID=Europe/Paris:20260226T113000
    assert_equal sample.timezone, 'Paris'
    assert_equal '2026-02-26T10:00:00+01:00', sample.local_iso8601(sample.start)
    assert_equal '2026-02-26T11:30:00+01:00', sample.local_iso8601(sample.end)
    assert_equal Time.utc(2026, 2, 26, 9, 0), sample.start_utc
    assert_equal Time.utc(2026, 2, 26, 10, 30), sample.end_utc
    assert_includes sample.venue, 'teratec.webex.com'
    assert_equal sample.organizer, 'Someone, SomeoneElse'
  end

  private

  def webmock(url, filename)
    file = Rails.root.join('test', 'fixtures', 'files', 'ingestion', filename)
    WebMock.stub_request(:get, url).to_return(status: 200, headers: {}, body: file.read)
  end
end
