require 'test_helper'
require 'stringio'

class EventRSSIngestorTest < ActiveSupport::TestCase
  setup do
    @ingestor = Ingestors::EventRSSIngestor.new
    mock_timezone
  end

  teardown do
    reset_timezone
  end

  test 'reads rss items from dublin core and native rss fields' do
    rss_feed_xml = <<~XML
      <?xml version="1.0"?>
      <rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/">
        <channel>
          <title>RSS Event Feed</title>

          <item>
            <title>Native RSS event title</title>
            <link>https://example.org/events/native</link>
            <description>Native RSS event description</description>
            <author>native.author@example.org (Native Event Author)</author>
            <category>native-event-category</category>
            <pubDate>Sat, 01 Jun 2024 09:00:00 GMT</pubDate>
            <dc:title>DC RSS event title</dc:title>
            <dc:description>DC RSS event description</dc:description>
            <dc:creator>DC Event Creator</dc:creator>
            <dc:subject>event-topic-a</dc:subject>
            <dc:type>workshop</dc:type>
            <dc:date>2024-06-01</dc:date>
            <dc:date>2024-06-02</dc:date>
            <dc:identifier>https://example.org/events/dc-url</dc:identifier>
            <dc:publisher>rss event publisher</dc:publisher>
          </item>

          <item>
            <title>Fallback RSS event title</title>
            <link>https://example.org/events/fallback</link>
            <description>Fallback RSS event description</description>
            <author>Fallback RSS Author</author>
            <category>fallback-event-category</category>
            <pubDate>Mon, 03 Jun 2024 12:00:00 GMT</pubDate>
          </item>
        </channel>
      </rss>
    XML

    read_xml(rss_feed_xml)

    assert_equal 2, @ingestor.events.count

    dc_event = @ingestor.events.first
    assert_equal 'DC RSS event title', dc_event.title
    assert_equal 'https://example.org/events/native', dc_event.url
    assert_equal 'DC RSS event description', dc_event.description
    assert_equal 'DC Event Creator', dc_event.organizer
    assert_equal 'rss event publisher', dc_event.contact
    assert_equal %w[event-topic-a native-event-category], dc_event.keywords
    assert_equal ['workshop'], dc_event.event_types
    assert_equal Time.utc(2024, 6, 1, 9, 0, 0), dc_event.start.utc
    assert_equal Date.new(2024, 6, 2), dc_event.end.to_date

    fallback_event = @ingestor.events.second
    assert_equal 'Fallback RSS event title', fallback_event.title
    assert_equal 'https://example.org/events/fallback', fallback_event.url
    assert_equal 'Fallback RSS event description', fallback_event.description
    assert_equal 'Fallback RSS Author', fallback_event.organizer
    assert_equal 'Fallback RSS Author', fallback_event.contact
    assert_equal ['fallback-event-category'], fallback_event.keywords
    assert_equal [], fallback_event.event_types
    assert_equal Time.utc(2024, 6, 3, 12, 0, 0), fallback_event.start.utc
    assert_equal Time.utc(2024, 6, 3, 12, 0, 0), fallback_event.end.utc
  end

  test 'reads atom items from dublin core and native atom fields' do
    atom_feed_xml = <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/">
        <title>Atom Event Feed</title>

        <entry>
          <title>Native Atom event title</title>
          <link href="https://example.org/atom-events/native" />
          <summary>Native Atom event summary</summary>
          <author><name>Native Atom Author</name></author>
          <category term="native-atom-event-category" />
          <published>2024-07-01T10:00:00Z</published>
          <updated>2024-07-02T11:00:00Z</updated>
          <dc:title>DC Atom event title</dc:title>
          <dc:description>DC Atom event description</dc:description>
          <dc:creator>DC Atom Creator</dc:creator>
          <dc:subject>atom-event-topic</dc:subject>
          <dc:type>seminar</dc:type>
          <dc:date>2024-07-01</dc:date>
          <dc:date>2024-07-02</dc:date>
          <dc:identifier>https://example.org/atom-events/dc-url</dc:identifier>
          <dc:publisher>atom event publisher</dc:publisher>
        </entry>

        <entry>
          <title>Fallback Atom event title</title>
          <link href="https://example.org/atom-events/fallback" />
          <content>Fallback Atom event content</content>
          <author><name>Fallback Atom Author</name></author>
          <category term="fallback-atom-event-category" />
          <published>2024-07-03T10:00:00Z</published>
          <updated>2024-07-04T11:00:00Z</updated>
        </entry>
      </feed>
    XML

    read_xml(atom_feed_xml)

    assert_equal 2, @ingestor.events.count

    dc_event = @ingestor.events.first
    assert_equal 'DC Atom event title', dc_event.title
    assert_equal 'https://example.org/atom-events/native', dc_event.url
    assert_equal 'DC Atom event description', dc_event.description
    assert_equal 'DC Atom Creator', dc_event.organizer
    assert_equal 'atom event publisher', dc_event.contact
    assert_equal %w[atom-event-topic native-atom-event-category], dc_event.keywords
    assert_equal ['seminar'], dc_event.event_types
    assert_equal Time.utc(2024, 7, 1, 10, 0, 0), dc_event.start.utc
    assert_equal Time.utc(2024, 7, 2, 11, 0, 0), dc_event.end.utc

    fallback_event = @ingestor.events.second
    assert_equal 'Fallback Atom event title', fallback_event.title
    assert_equal 'https://example.org/atom-events/fallback', fallback_event.url
    assert_equal 'Fallback Atom event content', fallback_event.description
    assert_equal 'Fallback Atom Author', fallback_event.organizer
    assert_equal 'Fallback Atom Author', fallback_event.contact
    assert_equal ['fallback-atom-event-category'], fallback_event.keywords
    assert_equal [], fallback_event.event_types
    assert_equal Time.utc(2024, 7, 3, 10, 0, 0), fallback_event.start.utc
    assert_equal Time.utc(2024, 7, 4, 11, 0, 0), fallback_event.end.utc
  end

  test 'reads bioschemas event from rss 1.0 rdf feed' do
    rss_10_bioschemas_feed_xml = <<~XML
      <?xml version="1.0"?>
      <rdf:RDF
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns="http://purl.org/rss/1.0/"
        xmlns:sdo="http://schema.org/"
        xmlns:dc="http://purl.org/dc/elements/1.1/">
        <channel rdf:about="https://example.org/rss10-bioschemas-events">
          <title>RSS 1.0 Bioschemas event feed</title>
          <link>https://example.org/rss10-bioschemas-events</link>
          <description>desc</description>
          <items>
            <rdf:Seq>
              <rdf:li rdf:resource="https://example.org/rss10-bioschemas/event-item"/>
            </rdf:Seq>
          </items>
        </channel>
        <item rdf:about="https://example.org/rss10-bioschemas/event-item">
          <title>Fallback RSS 1.0 event title</title>
          <link>https://example.org/rss10-bioschemas/event-item</link>
          <description>Fallback RSS 1.0 event description</description>
        </item>

        <sdo:Event rdf:about="https://example.org/rss10/bioschemas/event">
          <sdo:name>RSS 1.0 Bioschemas event title</sdo:name>
          <sdo:url rdf:resource="https://example.org/rss10/bioschemas/event"/>
          <sdo:startDate>2024-08-01</sdo:startDate>
          <sdo:endDate>2024-08-02</sdo:endDate>
        </sdo:Event>
      </rdf:RDF>
    XML

    read_xml(rss_10_bioschemas_feed_xml)

    assert_equal 2, @ingestor.events.count

    event = @ingestor.events.detect { |e| e.url == 'https://example.org/rss10/bioschemas/event' }
    refute_nil event
    assert_equal 'RSS 1.0 Bioschemas event title', event.title
    assert_equal 'https://example.org/rss10/bioschemas/event', event.url

    fallback_event = @ingestor.events.detect { |e| e.url == 'https://example.org/rss10-bioschemas/event-item' }
    refute_nil fallback_event
    assert_equal 'Fallback RSS 1.0 event title', fallback_event.title
  end

  test 'merges rss properties into bioschemas event for same url with bioschemas priority' do
    rss_10_bioschemas_merged_feed_xml = <<~XML
      <?xml version="1.0"?>
      <rdf:RDF
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns="http://purl.org/rss/1.0/"
        xmlns:sdo="http://schema.org/"
        xmlns:dc="http://purl.org/dc/elements/1.1/">
        <channel rdf:about="https://example.org/rss10-merged-events">
          <title>RSS 1.0 Bioschemas merged event feed</title>
          <link>https://example.org/rss10-merged-events</link>
          <description>desc</description>
          <items>
            <rdf:Seq>
              <rdf:li rdf:resource="https://example.org/rss10/merged/event"/>
            </rdf:Seq>
          </items>
        </channel>

        <item rdf:about="https://example.org/rss10/merged/event">
          <title>RSS 1.0 fallback event title</title>
          <link>https://example.org/rss10/merged/event</link>
          <description>RSS 1.0 fallback event description that should fill missing bioschemas value</description>
          <dc:creator>RSS 1.0 Merged Event Creator</dc:creator>
          <dc:subject>rss10-merged-event-subject</dc:subject>
          <dc:date>2024-08-01</dc:date>
        </item>

        <sdo:Event rdf:about="https://example.org/rss10/merged/event">
          <sdo:name>RSS 1.0 Bioschemas preferred event title</sdo:name>
          <sdo:url rdf:resource="https://example.org/rss10/merged/event"/>
        </sdo:Event>
      </rdf:RDF>
    XML

    read_xml(rss_10_bioschemas_merged_feed_xml)

    assert_equal 1, @ingestor.events.count

    event = @ingestor.events.first
    assert_equal 'RSS 1.0 Bioschemas preferred event title', event.title
    assert_equal 'https://example.org/rss10/merged/event', event.url
    assert_equal 'RSS 1.0 fallback event description that should fill missing bioschemas value', event.description
    assert_equal ['rss10-merged-event-subject'], event.keywords
    assert_equal 'RSS 1.0 Merged Event Creator', event.organizer
    assert_equal Date.new(2024, 8, 1), event.start.to_date
    assert_equal Date.new(2024, 8, 1), event.end.to_date
  end

  test 'reads feed from html alternate meta link' do
    start_url = 'https://www.youtube.com/@event_channel'
    feed_url = 'https://www.youtube.com/feeds/videos.xml?channel_id=UCevent123'

    html_with_alternate_feed_link = <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <link rel="alternate" type="application/rss+xml" href="https://www.youtube.com/feeds/videos.xml?channel_id=UCevent123" />
        </head>
        <body>Channel page</body>
      </html>
    HTML

    atom_feed_xml = <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Minimal Atom event feed</title>
        <entry>
          <title>Alternate feed event</title>
          <link href="https://example.org/atom-events/alternate" />
          <summary>Minimal content used for alternate-link test</summary>
          <author><name>Alternate Event Organizer</name></author>
          <updated>2024-07-02T11:00:00Z</updated>
        </entry>
      </feed>
    XML

    read_xml_map(
      {
        start_url => html_with_alternate_feed_link,
        feed_url => atom_feed_xml
      },
      start_url
    )

    assert_equal 1, @ingestor.events.count
    assert_includes @ingestor.messages, "HTML page detected, following feed link: #{feed_url}"
    assert_equal 'Alternate feed event', @ingestor.events.first.title
  end

  test 'logs parse error for invalid feed input' do
    read_xml('not valid rss or atom')

    assert_equal 1, @ingestor.messages.length
    assert_match(/^parsing feed failed with: This is not well formed XML/, @ingestor.messages.first)
    assert_empty @ingestor.events
  end

  private

  def read_xml(xml, url = 'https://example.org/event-feed.xml')
    @ingestor.stub(:open_url, StringIO.new(xml)) do
      @ingestor.read(url)
    end
  end

  def read_xml_map(url_to_content, start_url)
    @ingestor.stub(:open_url, lambda do |requested_url|
      content = url_to_content[requested_url]
      content.nil? ? nil : StringIO.new(content)
    end) do
      @ingestor.read(start_url)
    end
  end
end
