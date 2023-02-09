require 'test_helper'

class DansIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from dans' do
    source = @content_provider.sources.build(
      url: 'https://dans.knaw.nl/en/past-events/?filter=true&s=topics%20in%20heritage%20science',
      method: 'dans',
      enabled: true
    )

    ingestor = Ingestors::DansIngestor.new

    # check event doesn't
    new_title = 'Train-the-Trainer: An active learning course on understanding & using EOSC'
    new_url = 'https://eoscfuture.eu/eventsfuture/train-the-trainer-an-active-learning-course-on-understanding-using-eosc/'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 8 do
      freeze_time(Time.new(2019)) do
        VCR.use_cassette("ingestors/dans") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 8, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 8, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'DANS', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal ['Fair and Open data', 'Training & Outreach'], event.keywords
    assert_equal '2023-01-19 09:00:00'.to_time, event.start
    assert_equal '2023-01-19 17:00:00'.to_time, event.end
  end
end
