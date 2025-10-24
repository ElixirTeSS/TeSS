require 'test_helper'

class LinkCheckerTest < ActiveSupport::TestCase

  setup do
    @link_checker = LinkChecker.new(log: false)
  end

  test 'check collection' do
    event = events(:two)
    WebMock.stub_request(:head, event.url).to_return(status: 200)
    assert_nil event.link_monitor

    assert_no_difference('LinkMonitor.count') do
      @link_checker.check(Event.where(id: event.id))
    end

    assert_nil event.link_monitor
  end

  test 'check passing event url' do
    event = events(:two)
    WebMock.stub_request(:head, event.url).to_return(status: 200)
    assert_nil event.link_monitor

    assert_no_difference('LinkMonitor.count') do
      @link_checker.check_record(event)
    end

    assert_nil event.link_monitor
  end

  test 'check failing event url' do
    event = events(:two)
    WebMock.stub_request(:head, event.url).to_return(status: 404)
    assert_nil event.link_monitor

    assert_difference('LinkMonitor.count', 1) do
      @link_checker.check_record(event)
    end

    assert event.link_monitor
    assert event.link_monitor.failed_at
    assert_equal 404, event.link_monitor.code
  end

  test 'check failing event url that only responds to get' do
    event = events(:two)
    WebMock.stub_request(:head, event.url).to_return(status: 405)
    WebMock.stub_request(:get, event.url).to_return(status: 200)
    assert_nil event.link_monitor

    assert_no_difference('LinkMonitor.count') do
      @link_checker.check_record(event)
    end

    assert_nil event.link_monitor
  end

  test 'follows redirect' do
    event = events(:two)
    WebMock.stub_request(:head, event.url).to_return(status: 405)
    WebMock.stub_request(:get, event.url).to_return(status: 302, headers: { location: 'http://website.com' })
    WebMock.stub_request(:get, 'http://website.com').to_return(status: 404)
    assert_nil event.link_monitor

    assert_difference('LinkMonitor.count', 1) do
      @link_checker.check_record(event)
    end

    assert event.link_monitor
    assert event.link_monitor.failed_at
    assert_equal 404, event.link_monitor.code
  end

  test 'avoids redirect loop' do
    event = events(:two)
    WebMock.stub_request(:head, event.url).to_return(status: 405)
    WebMock.stub_request(:get, event.url).to_return(status: 302, headers: { location: 'http://website.com' })
    WebMock.stub_request(:get, 'http://website.com').to_return(status: 302, headers: { location: event.url })
    assert_nil event.link_monitor

    assert_difference('LinkMonitor.count', 1) do
      @link_checker.check_record(event)
    end

    assert event.link_monitor
    assert event.link_monitor.failed_at
    assert_equal 493, event.link_monitor.code
  end

  test 'check material with external resources' do
    WebMock.stub_request(:head, 'http://myurl.com/123').to_return(status: 200)
    WebMock.stub_request(:head, 'https://tess.elixir-uk.org/').to_return(status: 200)
    WebMock.stub_request(:head, 'https://bio.tools/tool/SR-Tesseler').to_return(status: 404)
    WebMock.stub_request(:head, 'https://fairsharing.org/bsg-p123456').to_return(status: 404)
    material = materials(:material_with_external_resource)

    assert_difference('LinkMonitor.count', 2) do
      @link_checker.check_record(material)
    end
  end

end