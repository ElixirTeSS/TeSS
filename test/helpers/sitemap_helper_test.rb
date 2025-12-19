require 'test_helper'

class SitemapHelperTest < ActionView::TestCase
  setup do
    @ingestor = DummyIngestor.new
    @messages = []
  end

  test 'parse_sitemap with url only returns url only' do
    url = 'https://test.com'
    assert_equal @ingestor.send(:parse_sitemap, url), [url]
  end

  test 'parse_sitemap returns parsed URLs from sitemap.xml' do
    sitemap_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>https://app.com/events/123</loc>
        </url>
        <url>
          <loc>https://app.com/events/456</loc>
        </url>
      </urlset>
    XML

    stub_request(:get, 'https://app.com/events/sitemap.xml')
      .to_return(status: 200, body: sitemap_xml, headers: { 'Content-Type' => 'application/xml' })

    urls = @ingestor.send(:parse_sitemap, 'https://app.com/events/sitemap.xml')
    assert_equal ['https://app.com/events/123', 'https://app.com/events/456'], urls
  end

  test 'parse_sitemap returns parsed URLs from sitemap.txt' do
    sitemap_txt = <<~TXT
      https://app.com/events/123
      https://app.com/events/456
    TXT

    stub_request(:get, 'https://app.com/events/sitemap.txt')
      .to_return(status: 200, body: sitemap_txt, headers: { 'Content-Type' => 'txt' })

    urls = @ingestor.send(:parse_sitemap, 'https://app.com/events/sitemap.txt')
    assert_equal ['https://app.com/events/123', 'https://app.com/events/456'], urls
  end

  private

  def webmock(url, filename)
    file = Rails.root.join('test', 'fixtures', 'files', 'ingestion', filename)
    WebMock.stub_request(:get, url).to_return(status: 200, headers: {}, body: file.read)
  end
end
