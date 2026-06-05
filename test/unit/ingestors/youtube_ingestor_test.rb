# frozen_string_literal: true

require 'test_helper'

class YoutubeIngestorTest < ActiveSupport::TestCase
  test 'discovers a YouTube playlist feed URL' do
    ingestor = Ingestors::YoutubeIngestor.new
    base_url = 'https://www.youtube.com/watch?v=abc123&list=PL123456789'
    expected = 'https://www.youtube.com/feeds/videos.xml?playlist_id=PL123456789'

    assert_equal expected, ingestor.send(:discover_feed_url, '', base_url)
    assert_equal ["Found Atom feed link from YouTube playlist URL, following: #{expected}"], ingestor.messages
  end

  test 'scrapes a YouTube playlist source end to end' do
    user = users(:scraper_user)
    provider = content_providers(:portal_provider)
    source = sources(:youtube_source)
    scraper = Scraper.new({ username: user.username, sources: [] })

    feed_url = source.url

    WebMock.stub_request(:get, feed_url).to_return(
      body: <<~XML
        <?xml version="1.0" encoding="utf-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>YouTube feed</title>
          <entry>
            <title>Video title</title>
            <link href="https://www.youtube.com/watch?v=abc123" rel="alternate" />
            <summary>Video summary</summary>
            <id>tag:youtube.com,2008:video:abc123</id>
            <published>2024-01-01T00:00:00Z</published>
            <updated>2024-01-01T00:00:00Z</updated>
          </entry>
        </feed>
      XML
    )

    with_settings(user_ingestion_methods: ['youtube']) do
      assert_difference('provider.materials.count', 1) do
        scraper.scrape(source, user)
      end
    end

    material = provider.materials.find_by(url: 'https://www.youtube.com/watch?v=abc123')
    assert material
    assert_equal 'Video title', material.title

    source.reload
    assert_equal 1, source.records_read
    assert_equal 1, source.records_written
  end
end
