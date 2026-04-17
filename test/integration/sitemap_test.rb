require 'test_helper'

class SitemapTest < ActionDispatch::IntegrationTest
  teardown do
    dir = Rails.root.join('public', 'test_sitemaps')
    FileUtils.rm_rf(dir) if dir.exist?
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

  test 'generates space-scoped sitemaps when spaces feature is enabled' do
    space = spaces(:plants)

    with_settings(feature: { spaces: true }) do
      SitemapGenerator::Interpreter.run(verbose: false)
    end

    # Global sitemap should include all content
    global_urls = parse
    assert_includes global_urls, material_url(materials(:good_material))
    assert_includes global_urls, material_url(materials(:plant_space_material))

    # Space sitemap should only include content for that space
    space_urls = parse_space(space)
    assert space_urls.any?
    assert_includes space_urls, "https://#{space.host}/about"
    assert_includes space_urls, "https://#{space.host}/materials/#{materials(:plant_space_material).friendly_id}"
    refute_includes space_urls, "https://#{space.host}/materials/#{materials(:good_material).friendly_id}"
  end

  private

  # Hacked to read files from disk rather than fetching via URL.
  # Host-agnostic: strips the scheme+host and reads from public/ using the path only.
  class LocalSitemapParser < SitemapParser
    def raw_sitemap
      uri = URI.parse(@url.strip)
      path = uri.path.delete_prefix('/')
      path = 'test_sitemaps/sitemap.xml' if path == 'sitemap.xml'
      Rails.root.join('public', path).read
    end
  end

  def parse
    LocalSitemapParser.new('http://www.example.com/sitemap.xml', { recurse: true }).to_a.uniq.map(&:strip)
  end

  def parse_space(space)
    # The index URL uses the space's host as both the URL authority and the subdirectory path,
    # since sitemaps are stored under sitemaps/<space.host>/ and served via that same host.
    index_url = "https://#{space.host}/test_sitemaps/#{space.host}/sitemap.xml"
    LocalSitemapParser.new(index_url, { recurse: true }).to_a.uniq.map(&:strip)
  end
end