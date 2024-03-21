require 'test_helper'

class SitemapTest < ActionDispatch::IntegrationTest
  teardown do
    dir = Rails.root.join('public', 'test_sitemaps')
    dir.glob('*.xml').each(&:delete)
    dir.delete
  end

  test 'generates sitemap' do
    SitemapGenerator::Interpreter.run(verbose: false)
    urls = parse
    assert urls.any?
    assert_includes urls, 'http://www.example.com/about'
    assert_includes urls, 'http://www.example.com/materials'
    assert_includes urls, material_url(materials(:good_material))
    assert_includes urls, event_url(events(:one))
    assert_includes urls, content_provider_url(content_providers(:goblet))
    assert_includes urls, workflow_url(workflows(:one))
    assert_includes urls, collection_url(collections(:one))
    assert_includes urls, learning_path_url(learning_paths(:one))
  end

  test 'excludes disabled features from sitemap' do
    with_settings(feature: { materials: false, events: false, content_providers: false, workflows: false, collections: false, learning_paths: false }) do
      SitemapGenerator::Interpreter.run(verbose: false)
    end
    urls = parse
    assert urls.any?
    assert_includes urls, 'http://www.example.com/about'
    refute_includes urls, 'http://www.example.com/materials'
    refute_includes urls, material_url(materials(:good_material))
    refute_includes urls, event_url(events(:one))
    refute_includes urls, content_provider_url(content_providers(:goblet))
    refute_includes urls, workflow_url(workflows(:one))
    refute_includes urls, collection_url(collections(:one))
    refute_includes urls, learning_path_url(learning_paths(:one))
  end

  private

  # Hacked to read files from disk rather than fetching via URL
  class LocalSitemapParser < SitemapParser
    def raw_sitemap
      path = @url.strip.sub('http://www.example.com/', '')
      path = 'test_sitemaps/sitemap.xml' if path == 'sitemap.xml'
      path = Rails.root.join('public', path)
      path.read
    end
  end

  def parse
    LocalSitemapParser.new('http://www.example.com/sitemap.xml', { recurse: true }).to_a.uniq.map(&:strip)
  end
end