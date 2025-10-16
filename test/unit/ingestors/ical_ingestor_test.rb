require 'test_helper'

class IcalIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    # mock_nominatim
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'sitemap not found' do
    source = @content_provider.sources.build(url: 'https://missing.org/sitemap.xml',
                                             method: 'ical',
                                             enabled: true)
    ingestor = Ingestors::IcalIngestor.new

    assert_no_difference('Event.count') do
      ingestor.read(source.url)
      ingestor.write(@user, @content_provider)
    end

    assert ingestor.events.empty?
    assert ingestor.materials.empty?
    assert_includes ingestor.messages[0], 'Extract from sitemap[https://missing.org/sitemap.xml] failed with:'
  end

  test 'ingest valid sitemap' do
    source = @content_provider.sources.build(url: 'https://app.com/events/sitemap.xml',
                                             method: 'ical',
                                             enabled: true)
    ingestor = Ingestors::IcalIngestor.new

    # check two events to be updated
    name = 'ical_event_1'
    event = events(:ical_event_1)
    refute event.nil?, "event[#{name}] not found"
    refute event.online?, "event[#{name}] online not matched"
    assert_equal 'Another Portal Provider', event.content_provider.title,
                 "event[#{name}] content provider not matched"

    name = 'ical_event_2'
    refute events(name).nil?, "fixture[#{name}] not found"
    title = 'PaCER Seminar: Computational Fluid Dynamics'
    url = 'https://pawsey.org.au/event/pacer-seminar-computational-fluid-dynamics/'
    event = check_event_exists title, url
    refute event.nil?, "event title[#{title}] not found"
    refute event.online?, "event title[#{title}] online not matched"
    assert_equal 'Another Portal Provider', event.content_provider.title,
                 "event title[#{title}] content provider not matched"

    assert_difference('Event.count', 4) do
      freeze_time(2019) do
        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)
      end
    end

    assert_equal 8, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 4, ingestor.stats[:events][:added]
    assert_equal 2, ingestor.stats[:events][:updated]
    assert_equal 2, ingestor.stats[:events][:rejected]

    # check individual events
    # check not found
    assert_includes ingestor.messages, "Process file url\[https://pawsey.org.au/events/\?ical=true\] failed with: 404 "

    # check rejected
    event = ingestor.events.detect { |e| e.title == 'NVIDIA cuQuantum Session' }
    assert event
    assert event.errors.added?(:url, :url, value: '123')
    event = ingestor.events.detect { |e| e.title == 'PaCER Seminar: Radio astronomy' }
    assert event
    assert event.errors.added?(:url, :blank)

    # check added
    title = 'Ask Me Anything: Porous media visualisation and LBPM'
    event = check_event_exists title, 'https://pawsey.org.au/event/ask-me-anything-porous-media-visualisation-and-lbpm/'
    assert event.online?, "event title[#{event.title}] online not matched"
    assert (!event.keywords.nil? and event.keywords.size == 2), "event title[#{event.title}] keywords.size not matched"
    assert event.keywords.include?('AMA'), "event title[#{event.title}] keyword[AMA] not found"
    assert event.keywords.include?('Visualisation'), "event title[#{event.title}] keyword[Visualisation] not found"

    title = 'Pawsey Intern Showcase 2022'
    event = check_event_exists title, 'https://pawsey.org.au/event/pawsey-intern-showcase-2022/'
    assert_includes event.description, 'The Pawsey Supercomputing Research Centre takes prides in its Summer Internship Program'
    assert_includes event.description, 'range of trainings we immerse students in during Week 1 of the Program (and throughout).'
    assert_equal 'Perth', event.timezone.to_s, "event title[#{event.title}] timezone not matched"
    assert_equal '2022-02-11 01:45:00 UTC', event.start.utc.to_s, "event title[#{event.title}] start not matched"
    assert_equal '2022-02-11 04:50:00 UTC', event.end.utc.to_s, "event title[#{event.title}] end not matched"

    title = 'P\'Con - Experience with porting and scaling codes on AMD GPUs'
    event = check_event_exists title, 'https://pawsey.org.au/event/experience-with-porting-and-scaling-codes-on-amd-gpus/'
    assert event.online?, "event title[#{title}] online not matched"

    title = 'Overview of High Performance Computing Resources at OLCF'
    event = check_event_exists title, 'https://pawsey.org.au/event/overview-of-high-performance-computing-resources-at-olcf/'
    refute event.online?, "event title[#{title}] online not matched"
    location = 'Pawsey Supercomputing Centre, 1 Bryce Avenue, Kensington, Western Australia, 6151, Australia'
    assert_equal location, event.venue, "event title[#{title}] venue not matched"
    # Geocoding is disabled so these fail TODO: Re-enable, but using cache + rate limiting
    # assert_equal 'Kensington', event.city, "event title[#{title}] city not matched"
    # assert_equal '6151', event.postcode, "event title[#{title}] postcode not matched"
    # assert_equal 'Australia', event.country, "event title[#{title}] country not matched"

    # TODO: check updated
    title = 'PaCER Seminar: Computational Fluid Dynamics'
    event = check_event_exists title, 'https://pawsey.org.au/event/pacer-seminar-computational-fluid-dynamics/'
    assert_equal '2022-06-15 03:00:00 UTC', event.end.utc.to_s, "event title[#{event.title}] updated end not matched"
    assert event.description != 'MyText', "event title[#{event.title}] description not updated"
    assert event.description.size > 100, "event title[#{event.title}] description too short"
    assert event.online?, "event title[#{event.title}] online not matched"
    assert_equal 2, event.keywords.size, "event title[#{event.title}] keywords size not matched"
    %w[Supercomputing Seminar].each do |keyword|
      assert event.keywords.include?(keyword), "event title[#{event.title}] keyword[#{keyword}] not found"
    end
    assert_equal 'Online, Virtual, Australia', event.venue, "event title[#{event.title}] venue not matched"
    assert event.city.nil?, "event title[#{event.title}] city not matched"
    assert event.postcode.nil?, "event title[#{event.title}] postcode not matched"
    assert event.country.nil?, "event title[#{event.title}] country not matched"

    title = "P'Con - Embracing new solutions for in-situ visualisation"
    event = check_event_exists title, 'https://pawsey.org.au/event/pcon-embracing-new-solutions-for-in-situ-visualisation/'
    assert event.online?, "event title[#{event.title}] online not matched"
    assert_equal 3, event.keywords.size, "event title[#{event.title}] keywords size not matched"
    %w[Supercomputing Conference Visualisation].each do |keyword|
      assert event.keywords.include?(keyword), "event title[#{event.title}] keyword[#{keyword}] not found"
    end
    assert_equal 'Online, Virtual, Australia', event.venue, "event title[#{event.title}] venue not matched"
    assert event.postcode.nil?, "event title[#{event.title}] postcode not matched"
    assert event.city.nil?, "event title[#{event.title}] city not matched"
    assert event.country.nil?, "event title[#{event.title}] country not matched"
  end

  test 'check single ical sources' do
    # override time
    assert_no_difference 'Event.count' do
      freeze_time(2019) do
        ingestor = Ingestors::IcalIngestor.new
        source = @content_provider.sources.build(
          url: 'https://pawsey.org.au/event/pcon-embracing-new-solutions-for-in-situ-visualisation/?ical=true',
          method: 'ical', enabled: true
        )

        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)

        assert_equal 1, ingestor.events.count
        assert ingestor.materials.empty?
        assert_equal 0, ingestor.stats[:events][:added]
        assert_equal 1, ingestor.stats[:events][:updated]
        assert_equal 0, ingestor.stats[:events][:rejected]

        ingestor = Ingestors::IcalIngestor.new
        source = @content_provider.sources.build(
          url: 'https://pawsey.org.au/event/pawsey-intern-showcase-2021/?ical=true',
          method: 'ical', enabled: true
        )

        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)

        assert_equal 1, ingestor.events.count
        assert ingestor.materials.empty?
        assert_equal 0, ingestor.stats[:events][:added]
        assert_equal 0, ingestor.stats[:events][:updated]
        assert_equal 1, ingestor.stats[:events][:rejected]

        event = ingestor.events.detect { |e| e.title == 'Pawsey Intern Showcase 2021' }
        assert event
        assert event.errors.added?(:url, :blank)
      end
    end

    # get updated
    title = 'P\'Con - Embracing new solutions for in-situ visualisation'
    url = 'https://pawsey.org.au/event/pcon-embracing-new-solutions-for-in-situ-visualisation/'
    event = check_event_exists title, url
    assert_equal 3, event.keywords.size
    %w[Supercomputing Conference Visualisation].each do |keyword|
      assert event.keywords.include?(keyword), "event title[#{event.title}] keyword[#{keyword}] not found"
    end
  end

  test 'process_calevent logs error when exception is raised' do
    ingestor = Ingestors::IcalIngestor.new
    calevent = Object.new # fake calevent

    # Stub a method that will raise an error
    def ingestor.assign_basic_info(*)
      raise StandardError, 'test failure'
    end

    ingestor.send(:process_calevent, calevent)

    assert_includes ingestor.messages.last, 'Process iCalendar failed with: test failure'
  end

  test 'to_export method' do
    ingestor = Ingestors::IcalIngestor.new
    indico_url_event = 'https://indico.cern.ch/event/1588342/'
    indico_url_event_with_ics = 'https://indico.cern.ch/event/1588342/event.ics' # ! when '/event', event.ics is singular
    indico_url_event_with_query = 'https://indico.cern.ch/event/1588342/?somerandom=urlparams&an=otherone'
    indico_url_event_with_query_with_ics = 'https://indico.cern.ch/event/1588342/event.ics?somerandom=urlparams&an=otherone'
    indico_url_category = 'https://indico.cern.ch/category/19377/'
    indico_url_category_with_ics = 'https://indico.cern.ch/category/19377/events.ics' # ! when '/category', eventS.ics is plural
    indico_url_category_with_query = 'https://indico.cern.ch/category/19377/?a=b&c=d'
    indico_url_category_with_query_with_ics = 'https://indico.cern.ch/category/19377/events.ics?a=b&c=d'
    url_with_ics = 'https://mywebsite.com/event/blabla/events.ics'
    url_with_query_with_ics = 'https://mywebsite.com/event/blabla/events.ics?john=doe&isstub=born'
    url_no_ical = 'https://mywebsite.com/event/blabla'
    url_with_ical = 'https://mywebsite.com/event/blabla?ical=true'

    # When indico link – event
    assert_equal ingestor.send(:to_export, indico_url_event), indico_url_event_with_ics # adds ics
    assert_equal ingestor.send(:to_export, indico_url_event_with_query), indico_url_event_with_query_with_ics # adds ics

    # When indico link – category
    assert_equal ingestor.send(:to_export, indico_url_category), indico_url_category_with_ics # adds ics
    assert_equal ingestor.send(:to_export, indico_url_category_with_query), indico_url_category_with_query_with_ics # adds ics

    # When non-indico link
    assert_equal ingestor.send(:to_export, url_with_ics), url_with_ics # keeps same
    assert_equal ingestor.send(:to_export, url_with_query_with_ics), url_with_query_with_ics # keeps same

    # When indico link which already has the /events.ics
    assert_equal ingestor.send(:to_export, indico_url_event_with_ics), indico_url_event_with_ics # keeps it as-is
    assert_equal ingestor.send(:to_export, indico_url_event_with_query_with_ics), indico_url_event_with_query_with_ics # keeps it as-is

    # When other url, adds the ical query param
    assert_equal ingestor.send(:to_export, url_no_ical), url_with_ical

    # When other url with ical query param, keep it as-is
    assert_equal ingestor.send(:to_export, url_with_ical), url_with_ical
  end

  private

  def check_event_exists(title, url)
    events = Event.where(title: title, url: url)
    assert (!events.nil? and events.size > 0), "event title[#{title}] not found"
    assert events.size < 2, "event[#{title}] duplicates found = #{events.size}"
    events.first
  end
end
