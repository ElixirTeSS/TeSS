require 'test_helper'

class EventCsvIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_nominatim
  end

  def run
    with_dresa_dictionaries do
      super
    end
  end

  test 'can ingest events from CSV file' do
    source = @content_provider.sources.build(
      url: 'https://raw.githubusercontent.com/nci900/NCI_feed_to_DReSA/master/event_NCI.csv',
      method: 'event_csv',
      enabled: true
    )

    ingestor = Ingestors::EventCsvIngestor.new

    assert_difference('Event.count', 14) do
      freeze_time(stub_time = Time.new(2021)) do
        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)
      end
    end

    assert_equal 14, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 14, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    assert_not_includes ingestor.messages, 'EventCsvIngestor: failed with: Illegal quoting'

    # check timezone transtation - Australia/Sydney -> Sydney
    title = 'Data Manipulation and Visualisation in Python'
    url = 'https://opus.nci.org.au/display/Help/Data+Manipulation+and+Visualisation+in+Python'
    event = get_event title, url
    refute_nil event
    assert_equal 'Sydney', event.timezone

    # check an entry
    title = 'Introduction to Gadi'
    url = 'https://opus.nci.org.au/display/Help/Introduction+to+Gadi'
    description = 'Introduction to Gadi is designed for new users, or users that want a refresher on the basics of Gadi.'
    event = get_event title, url
    refute_nil event

    # check required attributes
    assert_equal title, event.title
    assert_equal url, event.url
    assert_equal description, event.description, "Event title[#{title}] not matched"
    assert_equal DateTime.new(2022, 3, 3, 14, 0, 0), event.start
    assert_equal DateTime.new(2022, 3, 3, 15, 30, 0), event.end
    assert_equal 'Sydney', event.timezone
    assert_equal 'training.nci@anu.edu.au', event.contact
    assert_equal 'NCI', event.organizer
    check_array event.eligibility, ['by_invitation'], ['open_to_all']
    check_array event.host_institutions, ['NCI'], ['Intersect']
    refute event.online

    # check optional attributes
    assert_equal 'NCI, ANU, Ward Road', event.venue
    assert_equal 'Acton', event.city
    assert_equal 'Australia', event.country
    assert_equal '2601', event.postcode
    assert_equal 'To infinity and beyond', event.subtitle
    assert_equal '1.3 hours', event.duration
    assert_equal 'None', event.recognition
    check_array event.event_types, %w[webinar hackathon], ['workshop']
    assert_equal 'charge', event.cost_basis
    assert_equal 'AUD', event.cost_currency
    assert_equal 9.99, event.cost_value
    assert_equal 25, event.capacity
    check_array event.fields, ['BIOINFORMATICS', 'Software Engineering'], ['MATHEMATICS']
    check_array event.keywords, %w[Supercomputing Gadi]
    check_array event.target_audience, %w[ecr researcher phd mbr], ['ugrad']
    assert_equal 'To provide a basic intro to supercomputing on the **Gadi** system',
                 event.learning_objectives
    assert_equal "To get the most of this session, it would be good to have a basic awareness of:\n\n" +
                 "- Supercomputing\n" + "- Bioinformatics\n" + '- Software Design',
                 event.prerequisites
    assert_equal 'There are no technical requirements.',
                 event.tech_requirements
  end

  private

  def check_array(collection, values, exclusions = [])
    assert_not_nil collection
    assert_not_nil values
    assert_kind_of Array, collection
    assert_kind_of Array, values
    assert_equal collection.size, values.size
    values.each { |item| assert_includes collection, item }
    exclusions.each { |item| refute_includes collection, item } unless exclusions.nil?
  end

  def get_event(title, url, provider = nil)
    results = if provider.nil?
                Event.where(title: title, url: url)
              else
                Event.where(title: title, url: url, content_provider: provider)
              end
    results.nil? or results.empty? ? nil : results.first
  end
end
