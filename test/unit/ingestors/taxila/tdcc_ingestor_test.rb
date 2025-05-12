require 'test_helper'

class TdccIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from tdcc' do
    source = @content_provider.sources.build(
      url: 'https://tdcc.nl/evenementen/',
      method: 'tdcc',
      enabled: true
    )

    ingestor = Ingestors::Taxila::TdccIngestor.new

    # check event doesn't
    new_title = "Project Idea Generator - An Unconference by the Thematic DCC Social Sciences and Humanities"
    new_url = 'https://tdcc.nl/evenementen/project-idea-generator-an-unconference-by-the-thematic-dcc-social-sciences-humanities/'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 8 do
      freeze_time(2023) do
        VCR.use_cassette("ingestors/tdcc") do
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
    assert_equal 'TDCC', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal Time.zone.parse('Thu, 2 Apr 2023 13:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Thu, 2 Apr 2023 17:00:00.000000000 UTC +00:00'), event.end
    assert_equal 'Het Trippenhuis, Amsterdam', event.venue
  end
end
