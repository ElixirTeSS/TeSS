require 'test_helper'
require 'stringio'

class MaterialRSSIngestorTest < ActiveSupport::TestCase
  setup do
    @ingestor = Ingestors::MaterialRSSIngestor.new
  end

  test 'reads rss items from dublin core and native rss fields' do
    rss_feed_xml = <<~XML
      <?xml version="1.0"?>
      <rss version="2.0"
           xmlns:dc="http://purl.org/dc/elements/1.1/"
           xmlns:content="http://purl.org/rss/1.0/modules/content/">
        <channel>
          <title>RSS material feed</title>

          <item>
            <title>Native RSS title</title>
            <link>https://example.org/rss/native-link</link>
            <description>Native RSS description</description>
            <author>native.author@example.org (Native RSS Author)</author>
            <category>native-category</category>
            <guid>10.9999/native-rss-guid</guid>
            <pubDate>Tue, 02 Jan 2024 03:04:05 GMT</pubDate>
            <dc:title>DC RSS title</dc:title>
            <dc:description>DC RSS description</dc:description>
            <dc:creator>DC Creator One</dc:creator>
            <dc:creator>DC Creator Two</dc:creator>
            <dc:contributor>DC Contributor One</dc:contributor>
            <dc:contributor>DC Contributor Two</dc:contributor>
            <dc:rights>plain rights</dc:rights>
            <dc:rights>https://example.org/licenses/rss</dc:rights>
            <dc:date>2024-01-01</dc:date>
            <dc:date>2024-01-10</dc:date>
            <dc:identifier>https://example.org/rss/dc-url</dc:identifier>
            <dc:identifier>10.1234/rss-doi</dc:identifier>
            <dc:subject>dc-subject-a</dc:subject>
            <dc:subject>dc-subject-b</dc:subject>
            <dc:type>dc-type-a</dc:type>
            <dc:type>dc-type-b</dc:type>
            <dc:publisher>rss publisher</dc:publisher>
          </item>

          <item>
            <title>Plain Rights RSS title</title>
            <link>https://example.org/rss/plain-rights</link>
            <description>Plain rights RSS description</description>
            <dc:creator>Plain Rights RSS Creator</dc:creator>
            <dc:rights>plain-only-rights</dc:rights>
            <dc:date>not-a-date</dc:date>
            <dc:date>2024-01-11</dc:date>
            <dc:identifier>https://example.org/rss/plain-rights</dc:identifier>
            <dc:subject>plain-rights-subject</dc:subject>
            <dc:type>plain-rights-type</dc:type>
            <dc:publisher>plain rights publisher</dc:publisher>
          </item>

          <item>
            <title>Fallback RSS title</title>
            <link>https://example.org/rss/fallback</link>
            <author>Fallback RSS Author</author>
            <category>fallback-category-a</category>
            <category>fallback-category-b</category>
            <guid>10.5555/fallback-rss-guid</guid>
            <pubDate>Wed, 03 Jan 2024 04:05:06 GMT</pubDate>
            <content:encoded><![CDATA[Fallback RSS content encoded]]></content:encoded>
          </item>
        </channel>
      </rss>
    XML

    read_xml(rss_feed_xml)

    assert_equal 3, @ingestor.materials.count

    dc_material = @ingestor.materials.first
    assert_equal 'DC RSS title', dc_material.title
    assert_equal 'https://example.org/rss/native-link', dc_material.url
    assert_equal 'DC RSS description', dc_material.description
    assert_equal ['DC Creator One', 'DC Creator Two', 'native.author@example.org (Native RSS Author)'], dc_material.authors
    assert_equal ['DC Contributor One', 'DC Contributor Two'], dc_material.contributors
    assert_equal 'https://example.org/licenses/rss', dc_material.licence
    assert_equal Date.new(2024, 1, 1), dc_material.date_created
    assert_equal Time.utc(2024, 1, 2, 3, 4, 5), dc_material.date_published.utc
    assert_equal Date.new(2024, 1, 10), dc_material.date_modified
    assert_equal 'https://doi.org/10.1234/rss-doi', dc_material.doi
    assert_equal %w[dc-subject-a dc-subject-b native-category], dc_material.keywords
    assert_equal %w[dc-type-a dc-type-b], dc_material.resource_type
    assert_equal 'rss publisher', dc_material.contact

    plain_rights_material = @ingestor.materials.second
    assert_equal 'Plain Rights RSS title', plain_rights_material.title
    assert_equal 'https://example.org/rss/plain-rights', plain_rights_material.url
    assert_equal 'Plain rights RSS description', plain_rights_material.description
    assert_equal ['Plain Rights RSS Creator'], plain_rights_material.authors
    assert_equal [], plain_rights_material.contributors
    assert_equal 'plain-only-rights', plain_rights_material.licence
    assert_equal Date.new(2024, 1, 11), plain_rights_material.date_created
    assert_nil plain_rights_material.date_modified
    assert_nil plain_rights_material.doi
    assert_equal ['plain-rights-subject'], plain_rights_material.keywords
    assert_equal ['plain-rights-type'], plain_rights_material.resource_type
    assert_equal 'plain rights publisher', plain_rights_material.contact

    fallback_material = @ingestor.materials.third
    assert_equal 'Fallback RSS title', fallback_material.title
    assert_equal 'https://example.org/rss/fallback', fallback_material.url
    assert_equal 'Fallback RSS content encoded', fallback_material.description
    assert_equal ['Fallback RSS Author'], fallback_material.authors
    assert_equal [], fallback_material.contributors
    assert_equal 'notspecified', fallback_material.licence
    assert_equal Time.utc(2024, 1, 3, 4, 5, 6), fallback_material.date_created.utc
    assert_equal Time.utc(2024, 1, 3, 4, 5, 6), fallback_material.date_published.utc
    assert_equal Time.utc(2024, 1, 3, 4, 5, 6), fallback_material.date_modified.utc
    assert_equal 'https://doi.org/10.5555/fallback-rss-guid', fallback_material.doi
    assert_equal %w[fallback-category-a fallback-category-b], fallback_material.keywords
    assert_equal [], fallback_material.resource_type
    assert_equal 'Fallback RSS Author', fallback_material.contact
  end

  test 'reads atom items from dublin core and native atom fields' do
    atom_feed_xml = <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom"
            xmlns:dc="http://purl.org/dc/elements/1.1/">
        <title>Atom material feed</title>

        <entry>
          <title>Native Atom title</title>
          <link href="https://example.org/atom/native-link" />
          <summary>Native Atom summary</summary>
          <author><name>Native Atom Author</name></author>
          <category term="native-atom-category" />
          <id>10.9999/native-atom-id</id>
          <published>2024-02-02T03:04:05Z</published>
          <updated>2024-02-03T03:04:05Z</updated>
          <dc:title>DC Atom title</dc:title>
          <dc:description>DC Atom description</dc:description>
          <dc:creator>DC Atom Creator One</dc:creator>
          <dc:creator>DC Atom Creator Two</dc:creator>
          <dc:contributor>DC Atom Contributor One</dc:contributor>
          <dc:rights>plain atom rights</dc:rights>
          <dc:rights>https://example.org/licenses/atom</dc:rights>
          <dc:date>2024-02-01</dc:date>
          <dc:date>2024-02-05</dc:date>
          <dc:identifier>https://example.org/atom/dc-url</dc:identifier>
          <dc:identifier>https://doi.org/10.1234/atom-doi</dc:identifier>
          <dc:subject>atom-dc-subject</dc:subject>
          <dc:type>atom-dc-type</dc:type>
          <dc:publisher>atom publisher</dc:publisher>
        </entry>

        <entry>
          <title>Plain Rights Atom title</title>
          <link href="https://example.org/atom/plain-rights" />
          <summary>Plain rights Atom description</summary>
          <dc:creator>Plain Rights Atom Creator</dc:creator>
          <dc:rights>plain-atom-rights</dc:rights>
          <dc:date>invalid-date</dc:date>
          <dc:date>2024-02-11</dc:date>
          <dc:identifier>https://example.org/atom/plain-rights</dc:identifier>
          <dc:subject>plain-atom-subject</dc:subject>
          <dc:type>plain-atom-type</dc:type>
          <dc:publisher>plain atom publisher</dc:publisher>
        </entry>

        <entry>
          <title>Fallback Atom title</title>
          <link href="https://example.org/atom/fallback" />
          <content>Fallback Atom content</content>
          <author><name>Fallback Atom Author</name></author>
          <category term="fallback-atom-category-a" />
          <category term="fallback-atom-category-b" />
          <id>10.5555/fallback-atom-id</id>
          <published>2024-03-04T05:06:07Z</published>
          <updated>2024-03-05T06:07:08Z</updated>
        </entry>
      </feed>
    XML

    read_xml(atom_feed_xml)

    assert_equal 3, @ingestor.materials.count

    dc_material = @ingestor.materials.first
    assert_equal 'DC Atom title', dc_material.title
    assert_equal 'https://example.org/atom/native-link', dc_material.url
    assert_equal 'DC Atom description', dc_material.description
    assert_equal ['DC Atom Creator One', 'DC Atom Creator Two', 'Native Atom Author'], dc_material.authors
    assert_equal ['DC Atom Contributor One'], dc_material.contributors
    assert_equal 'https://example.org/licenses/atom', dc_material.licence
    assert_equal Date.new(2024, 2, 1), dc_material.date_created
    assert_equal Time.utc(2024, 2, 2, 3, 4, 5), dc_material.date_published.utc
    assert_equal Date.new(2024, 2, 5), dc_material.date_modified
    assert_equal 'https://doi.org/10.1234/atom-doi', dc_material.doi
    assert_equal %w[atom-dc-subject native-atom-category], dc_material.keywords
    assert_equal ['atom-dc-type'], dc_material.resource_type
    assert_equal 'atom publisher', dc_material.contact

    plain_rights_material = @ingestor.materials.second
    assert_equal 'Plain Rights Atom title', plain_rights_material.title
    assert_equal 'https://example.org/atom/plain-rights', plain_rights_material.url
    assert_equal 'Plain rights Atom description', plain_rights_material.description
    assert_equal ['Plain Rights Atom Creator'], plain_rights_material.authors
    assert_equal [], plain_rights_material.contributors
    assert_equal 'plain-atom-rights', plain_rights_material.licence
    assert_equal Date.new(2024, 2, 11), plain_rights_material.date_created
    assert_nil plain_rights_material.date_modified
    assert_nil plain_rights_material.doi
    assert_equal ['plain-atom-subject'], plain_rights_material.keywords
    assert_equal ['plain-atom-type'], plain_rights_material.resource_type
    assert_equal 'plain atom publisher', plain_rights_material.contact

    fallback_material = @ingestor.materials.third
    assert_equal 'Fallback Atom title', fallback_material.title
    assert_equal 'https://example.org/atom/fallback', fallback_material.url
    assert_equal 'Fallback Atom content', fallback_material.description
    assert_equal ['Fallback Atom Author'], fallback_material.authors
    assert_equal [], fallback_material.contributors
    assert_equal 'notspecified', fallback_material.licence
    assert_equal Time.utc(2024, 3, 4, 5, 6, 7), fallback_material.date_created.utc
    assert_equal Time.utc(2024, 3, 4, 5, 6, 7), fallback_material.date_published.utc
    assert_equal Time.utc(2024, 3, 5, 6, 7, 8), fallback_material.date_modified.utc
    assert_equal 'https://doi.org/10.5555/fallback-atom-id', fallback_material.doi
    assert_equal %w[fallback-atom-category-a fallback-atom-category-b], fallback_material.keywords
    assert_equal [], fallback_material.resource_type
    assert_equal 'Fallback Atom Author', fallback_material.contact
  end

  test 'logs parse error for invalid feed input' do
    read_xml('not valid rss or atom')

    assert_equal 2, @ingestor.messages.length
    assert_match(/^parsing feed failed with: This is not well formed XML/, @ingestor.messages.first)
    assert_match(%r{^Attempted HTML feed discovery, but no RSS/Atom alternate feed link was found in:},
           @ingestor.messages.second)
    assert_empty @ingestor.materials
  end

  test 'reads rss 0.91 feed' do
    rss_091_feed_xml = <<~XML
      <?xml version="1.0"?>
      <rss version="0.91">
        <channel>
          <title>RSS 0.91 feed</title>
          <link>https://example.org/rss091</link>
          <description>desc</description>
          <item>
            <title>RSS 0.91 title</title>
            <link>https://example.org/rss091/item</link>
            <description>RSS 0.91 description</description>
          </item>
        </channel>
      </rss>
    XML

    read_xml(rss_091_feed_xml)

    assert_equal 1, @ingestor.materials.count

    material = @ingestor.materials.first
    assert_equal 'RSS 0.91 title', material.title
    assert_equal 'https://example.org/rss091/item', material.url
    assert_equal 'RSS 0.91 description', material.description
    assert_equal [], material.keywords
    assert_equal 'notspecified', material.licence
    assert_nil material.doi
    assert_nil material.contact
  end

  test 'reads rss 1.0 feed' do
    rss_10_feed_xml = <<~XML
      <?xml version="1.0"?>
      <rdf:RDF
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns="http://purl.org/rss/1.0/">
        <channel rdf:about="https://example.org/rss10">
          <title>RSS 1.0 feed</title>
          <link>https://example.org/rss10</link>
          <description>desc</description>
          <items>
            <rdf:Seq>
              <rdf:li rdf:resource="https://example.org/rss10/item"/>
            </rdf:Seq>
          </items>
        </channel>
        <item rdf:about="https://example.org/rss10/item">
          <title>RSS 1.0 title</title>
          <link>https://example.org/rss10/item</link>
          <description>RSS 1.0 description</description>
          <dc:creator xmlns:dc="http://purl.org/dc/elements/1.1/">RSS 1.0 Creator</dc:creator>
          <dc:subject xmlns:dc="http://purl.org/dc/elements/1.1/">rss10-subject</dc:subject>
          <dc:identifier xmlns:dc="http://purl.org/dc/elements/1.1/">10.1111/rss10doi</dc:identifier>
          <dc:date xmlns:dc="http://purl.org/dc/elements/1.1/">2024-04-01</dc:date>
        </item>
      </rdf:RDF>
    XML

    read_xml(rss_10_feed_xml)

    assert_equal 1, @ingestor.materials.count

    material = @ingestor.materials.first
    assert_equal 'RSS 1.0 title', material.title
    assert_equal 'https://example.org/rss10/item', material.url
    assert_equal 'RSS 1.0 description', material.description
    assert_equal ['RSS 1.0 Creator'], material.authors
    assert_equal ['rss10-subject'], material.keywords
    assert_equal 'https://doi.org/10.1111/rss10doi', material.doi
    assert_equal Date.new(2024, 4, 1), material.date_created.to_date
    assert_equal Date.new(2024, 4, 1), material.date_modified.to_date
  end

  test 'reads bioschemas learning resource from rss 1.0 rdf feed' do
    rss_10_bioschemas_feed_xml = <<~XML
      <?xml version="1.0"?>
      <rdf:RDF
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns="http://purl.org/rss/1.0/"
        xmlns:sdo="http://schema.org/"
        xmlns:dc="http://purl.org/dc/terms/">
        <channel rdf:about="https://example.org/rss10-bioschemas">
          <title>RSS 1.0 Bioschemas feed</title>
          <link>https://example.org/rss10-bioschemas</link>
          <description>desc</description>
          <items>
            <rdf:Seq>
              <rdf:li rdf:resource="https://example.org/rss10-bioschemas/item"/>
            </rdf:Seq>
          </items>
        </channel>
        <item rdf:about="https://example.org/rss10-bioschemas/item">
          <title>Fallback RSS 1.0 title</title>
          <link>https://example.org/rss10-bioschemas/item</link>
          <description>Fallback RSS 1.0 description</description>
        </item>

        <sdo:LearningResource rdf:about="https://example.org/rss10/bioschemas/material">
          <dc:conformsTo>
            <sdo:CreativeWork rdf:about="https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE" />
          </dc:conformsTo>
          <sdo:name>RSS 1.0 Bioschemas title</sdo:name>
          <sdo:url rdf:resource="https://example.org/rss10/bioschemas/material"/>
          <sdo:license rdf:resource="https://opensource.org/licenses/MIT"/>
        </sdo:LearningResource>
      </rdf:RDF>
    XML

    read_xml(rss_10_bioschemas_feed_xml)

    assert_equal 2, @ingestor.materials.count

    material = @ingestor.materials.detect { |m| m.url == 'https://example.org/rss10/bioschemas/material' }
    refute_nil material
    assert_equal 'RSS 1.0 Bioschemas title', material.title
    assert_equal 'https://example.org/rss10/bioschemas/material', material.url
    assert_equal 'https://opensource.org/licenses/MIT', material.licence

    fallback_material = @ingestor.materials.detect { |m| m.url == 'https://example.org/rss10-bioschemas/item' }
    refute_nil fallback_material
    assert_equal 'Fallback RSS 1.0 title', fallback_material.title
  end

  test 'merges rss properties into bioschemas material for same url with bioschemas priority' do
    rss_10_bioschemas_merged_feed_xml = <<~XML
      <?xml version="1.0"?>
      <rdf:RDF
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns="http://purl.org/rss/1.0/"
        xmlns:sdo="http://schema.org/"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:dct="http://purl.org/dc/terms/">
        <channel rdf:about="https://example.org/rss10-merged">
          <title>RSS 1.0 Bioschemas merged feed</title>
          <link>https://example.org/rss10-merged</link>
          <description>desc</description>
          <items>
            <rdf:Seq>
              <rdf:li rdf:resource="https://example.org/rss10/merged/material"/>
            </rdf:Seq>
          </items>
        </channel>

        <item rdf:about="https://example.org/rss10/merged/material">
          <title>RSS 1.0 fallback title</title>
          <link>https://example.org/rss10/merged/material</link>
          <description>RSS 1.0 fallback description that should fill missing bioschemas value</description>
          <dc:creator>RSS 1.0 Merged Creator</dc:creator>
          <dc:subject>rss10-merged-subject</dc:subject>
          <dc:date>2024-05-01</dc:date>
        </item>

        <sdo:LearningResource rdf:about="https://example.org/rss10/merged/material">
          <dct:conformsTo>
            <sdo:CreativeWork rdf:about="https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE" />
          </dct:conformsTo>
          <sdo:name>RSS 1.0 Bioschemas preferred title</sdo:name>
          <sdo:url rdf:resource="https://example.org/rss10/merged/material"/>
          <sdo:license rdf:resource="https://opensource.org/licenses/Apache-2.0"/>
        </sdo:LearningResource>
      </rdf:RDF>
    XML

    read_xml(rss_10_bioschemas_merged_feed_xml)

    assert_equal 1, @ingestor.materials.count

    material = @ingestor.materials.first
    assert_equal 'RSS 1.0 Bioschemas preferred title', material.title
    assert_equal 'https://example.org/rss10/merged/material', material.url
    assert_equal 'https://opensource.org/licenses/Apache-2.0', material.licence
    assert_equal 'RSS 1.0 fallback description that should fill missing bioschemas value', material.description
    assert_equal ['rss10-merged-subject'], material.keywords
    assert_equal ['RSS 1.0 Merged Creator'], material.authors
    assert_equal Date.new(2024, 5, 1), material.date_created.to_date
    assert_equal Date.new(2024, 5, 1), material.date_modified.to_date
  end

  test 'reads feed from html alternate meta link' do
    start_url = 'https://www.youtube.com/@example'
    feed_url = 'https://www.youtube.com/feeds/videos.xml?channel_id=UC123456789'

    html_with_alternate_feed_link = <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>Channel</title>
          <link rel="alternate" type="application/rss+xml" href="https://www.youtube.com/feeds/videos.xml?channel_id=UC123456789" />
        </head>
        <body>Channel page</body>
      </html>
    HTML

    atom_feed_xml = <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Minimal Atom material feed</title>
        <entry>
          <title>Alternate feed material</title>
          <link href="https://example.org/atom/alternate-material" />
          <summary>Minimal content used for alternate-link test</summary>
          <author><name>Alternate Feed Author</name></author>
          <updated>2024-02-02T03:04:05Z</updated>
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

    assert_equal 1, @ingestor.materials.count
    assert_includes @ingestor.messages,
            "Found RSS/Atom alternate feed link during HTML discovery, following: #{feed_url}"
    assert_equal 'Alternate feed material', @ingestor.materials.first.title
  end

  test 'uses native atom title and description taking precedence over media extension' do
    atom_feed_xml = <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom"
            xmlns:media="http://search.yahoo.com/mrss/">
        <title>Atom media precedence feed</title>

        <entry>
          <id>yt:video:abc123</id>
          <title>Native Atom title wins</title>
          <link rel="alternate" href="https://example.org/atom/media-precedence" />
          <summary>Native Atom summary wins</summary>
          <author><name>Atom Author</name></author>
          <published>2024-02-02T03:04:05Z</published>
          <updated>2024-02-03T03:04:05Z</updated>
          <media:group>
            <media:title>Media title ignored</media:title>
            <media:description>Media description ignored</media:description>
          </media:group>
        </entry>
      </feed>
    XML

    read_xml(atom_feed_xml)

    assert_equal 1, @ingestor.materials.count
    material = @ingestor.materials.first
    assert_equal 'Native Atom title wins', material.title
    assert_equal 'Native Atom summary wins', material.description
  end

  test 'uses media extension title and description for atom item when native ones are missing' do
    atom_feed_xml = <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom"
            xmlns:media="http://search.yahoo.com/mrss/">
        <title>Atom media extension feed</title>

        <entry>
          <id>yt:video:fallback123</id>
          <link rel="alternate" href="https://example.org/atom/media-extension-fallback" />
          <author><name>Atom Author</name></author>
          <published>2024-02-02T03:04:05Z</published>
          <updated>2024-02-03T03:04:05Z</updated>
          <media:group>
            <media:title>Media title used here</media:title>
            <media:description>Media description used here</media:description>
          </media:group>
        </entry>
      </feed>
    XML

    read_xml(atom_feed_xml)

    assert_equal 1, @ingestor.materials.count
    material = @ingestor.materials.first
    assert_equal 'Media title used here', material.title
    assert_equal 'Media description used here', material.description
  end

  test 'parses media group description through rss media extension' do
    atom_feed_xml = <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom"
            xmlns:media="http://search.yahoo.com/mrss/">
        <title>Media extension feed</title>
        <id>urn:feed:test</id>
        <updated>2024-01-01T00:00:00Z</updated>

        <entry>
          <id>urn:entry:test</id>
          <title>Media extension title</title>
          <link rel="alternate" href="https://example.org/atom/media-extension" />
          <updated>2024-01-01T00:00:00Z</updated>
          <media:group>
            <media:description>Media extension description</media:description>
          </media:group>
        </entry>
      </feed>
    XML

    feed = RSS::Parser.parse(atom_feed_xml, validate: false, ignore_unknown_element: true)
    item = feed.items.first

    assert item.respond_to?(:media_group)
    assert_equal 'Media extension description', item.media_group.media_description
  end

  test 'uses itunes extension summary for rss item when native description is missing' do
    rss_feed_xml = <<~XML
      <?xml version="1.0"?>
      <rss version="2.0"
           xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
        <channel>
          <title>RSS iTunes extension feed</title>
          <item>
            <title>RSS item with iTunes summary</title>
            <link>https://example.org/rss/itunes-summary</link>
            <author>RSS Author</author>
            <pubDate>Fri, 02 Feb 2024 03:04:05 GMT</pubDate>
            <itunes:summary>iTunes summary used here</itunes:summary>
            <itunes:author>iTunes Author</itunes:author>
          </item>
        </channel>
      </rss>
    XML

    read_xml(rss_feed_xml)

    assert_equal 1, @ingestor.materials.count
    material = @ingestor.materials.first
    assert_equal 'RSS item with iTunes summary', material.title
    assert_equal 'iTunes summary used here', material.description
    assert_includes material.authors, 'RSS Author'
    assert_includes material.authors, 'iTunes Author'
  end

  private

  def read_xml(xml, url = 'https://example.org/feed.xml')
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
