require 'test_helper'
require 'minitest/autorun'

class FourtuGptLlmIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from 4tu' do
    source = @content_provider.sources.build(
      url: 'https://www.4tu.nl/en/agenda/',
      method: '4tu',
      enabled: true
    )

    ingestor = Ingestors::FourtuLlmIngestor.new

    # check event doesn't
    new_title = '4TU-meeting National Technology Strategy'
    refute Event.where(title: new_title).any?

    run_res = '{
      "title":"4TU-meeting National Technology Strategy",
      "start":"2024-07-03T12:30:00+02:00",
      "end":"2024-07-03T19:00:00+02:00",
      "venue":"Basecamp, Nijverheidsweg 16A, 3534 AM Utrecht (https://basecamputrecht.nl)",
      "description":"My cool description",
      "nonsense_attr":"My cool nonsense attribute"
    }'.gsub(/\n/, '')
    mock_client = Minitest::Mock.new
    8.times do 
      mock_client.expect(:chat, {'choices'=> {0=> {'message'=> {'content'=> run_res}}}}, parameters: Object)
    end
    # run task
    assert_difference 'Event.count', 1 do
      freeze_time(2019) do
        VCR.use_cassette("ingestors/4tu_gpt_llm") do
          OpenAI::Client.stub(:new, mock_client) do
            with_settings({ llm_scraper: { model: 'chatgpt', model_version: 'GPT-3.5' } }) do
              ingestor.read(source.url)
              ingestor.write(@user, @content_provider)
            end
          end
        end
      end
    end

    assert_equal 4, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 1, ingestor.stats[:events][:added]
    assert_equal 3, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title).first
    assert event
    assert_equal new_title, event.title

    # check other fields
    assert_equal Time.zone.parse('Wed, 3 Jul 2024 12:30:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Wed, 3 Jul 2024 19:00:00.000000000 UTC +00:00'), event.end
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Basecamp, Nijverheidsweg 16A, 3534 AM Utrecht (https://basecamputrecht.nl)', event.venue
    assert_equal 'LLM', event.source
  end
end
