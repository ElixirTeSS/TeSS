require 'test_helper'

class ProviderIngestionTest < ActiveSupport::TestCase
  setup do
    @ingestor = Ingestors::BioschemasIngestor.new
    @portal = content_providers(:portal_provider)
    @user = users(:scraper_user)
    @ingestor.ingesting_content_provider = @portal
    @provider = { name: 'Imported provider', url: 'https://provider.example.org' }
  end

  test 'provider identity uses URL and excludes nodes and candidates without URLs' do
    existing = content_providers(:organisation_provider)
    candidates = [
      { name: "ELIXIR #{nodes(:good).name}", url: 'https://node.example.org' },
      { name: existing.title },
      @provider,
      { name: 'A different name', url: existing.url }
    ]
    assert_equal existing, @ingestor.find_provider_by_extracted_urls(candidates)
    assert_nil @ingestor.find_provider_by_extracted_urls(candidates.first(2))

    stub_request(:get, @provider[:url]).to_return(body: '')
    different_url = @provider.merge(name: existing.title)
    provider = @ingestor.find_provider_by_extracted_urls([different_url])
    assert provider.new_record?
    assert_nil ContentProvider.check_exists(provider)
  end

  test 'provider selection does not depend on metadata richness' do
    stub_request(:get, @provider[:url]).to_return(body: '')
    other = { name: 'Other provider', url: 'https://other-provider.example.org' }
    other_request = stub_request(:get, other[:url]).to_return(body: '<meta property="og:description" content="Rich metadata">')

    assert_equal @provider[:url], @ingestor.find_provider_by_extracted_urls([@provider, other]).url
    assert_not_requested other_request
  end

  test 'sitemap registry metadata takes precedence across page hosts and repeated providers are reused' do
    registry_url = 'https://REGISTRY.example.org/content_providers/provider'
    source_url = 'https://registry.example.org/sitemap.txt'
    pages = %w[https://mirror.example.org/one https://mirror.example.org/two]
    stub_request(:get, source_url).to_return(body: pages.join("\n"))
    pages.each_with_index do |page, index|
      stub_request(:get, page).to_return(body: {
        '@context' => 'http://schema.org', '@type' => 'LearningResource',
        name: "Material #{index}", description: 'Training material', url: page,
        provider: @provider.merge('@type' => 'Organization', subjectOf: registry_url)
      }.to_json)
    end
    homepage = stub_request(:get, @provider[:url]).to_return(
      body: '<meta property="og:description" content="Homepage description"><meta property="og:image" content="https://images.example.org/logo.png">'
    )
    stub_request(:get, registry_url).to_return(
      body: '<meta property="og:description" content="Registry description"><meta name="keywords" content="training, FAIR data">'
    )

    @ingestor.read(source_url)
    assert_equal 2, @ingestor.materials.size
    assert_equal 1, @ingestor.providers.size
    provider = @ingestor.providers.first
    assert_same provider, @ingestor.materials.last.content_provider
    assert_equal 'Registry description', provider.description
    assert_equal ['training', 'FAIR data'], provider.keywords
    assert_nil provider.image_url
    assert_not_requested homepage
    assert_same provider, @ingestor.find_provider_by_extracted_urls([@provider])
    assert_requested :get, registry_url, times: 1
  end

  test 'unavailable or empty registry metadata falls back to the homepage with useful diagnostics' do
    @ingestor.provider_metadata_host = 'registry.example.org'
    failed_url = 'https://registry.example.org/failed'
    empty_url = 'https://registry.example.org/empty'
    stub_request(:get, failed_url).to_timeout
    stub_request(:get, empty_url).to_return(body: '')
    stub_request(:get, @provider[:url]).to_return(body: '<meta property="og:description" content="Homepage description">')

    provider = @ingestor.find_provider_by_extracted_urls([
      @provider.merge(see_also: [@provider[:url], 'not a URL', failed_url, empty_url])
    ])
    assert_equal 'Homepage description', provider.description
    assert_includes @ingestor.messages.join("\n"), failed_url
    assert_includes @ingestor.messages, 'Invalid content provider metadata URL: not a URL'
    assert_requested :get, empty_url

    @ingestor = Ingestors::BioschemasIngestor.new
    stub_request(:get, @provider[:url]).to_return(status: 404)
    provider = @ingestor.find_provider_by_extracted_urls([@provider])
    assert_nil provider.description
    assert_equal 1, @ingestor.messages.grep(/Couldn't open URL/).size
    assert_empty @ingestor.messages.grep(/Couldn't read content provider metadata/)
  end

  test 'provider enrichment only applies supported automatic parsing fields' do
    stub_request(:get, @provider[:url]).to_return(
      body: '<meta property="og:description" content="Training for professors">'
    )
    with_settings(feature: { auto_parse_vars: %w[target_audience keywords] }) do
      @ingestor.stub(:auto_parse, ->(field, _description) {
        assert_equal :keywords, field
        ['training']
      }) do
        provider = @ingestor.find_provider_by_extracted_urls([@provider])
        assert_equal ['training'], provider.keywords
        refute provider.respond_to?(:target_audience)
      end
    end
  end

  test 'providers are only listed and written when referenced after filtering' do
    stub_request(:get, @provider[:url]).to_return(body: '')
    provider = @ingestor.find_provider_by_extracted_urls([@provider])
    assert_empty @ingestor.providers
    add_material(provider)
    existing = content_providers(:organisation_provider)
    @ingestor.add_event(title: 'Existing provider event', url: 'https://events.example.org/one', content_provider: existing)
    assert_equal [existing, provider], @ingestor.providers

    source = Source.new(source_filters: [SourceFilter.new(mode: 'block', property: 'title', value: 'Imported material')])
    @ingestor.filter(source)
    assert_equal [existing], @ingestor.providers
    assert_no_difference('ContentProvider.count') { @ingestor.write(@user, @portal) }
  end

  test 'provider rejection uses the portal and does not inflate resource statistics' do
    provider = ContentProvider.new(url: @provider[:url])
    add_material(provider)

    assert_no_difference('ContentProvider.count') do
      assert_difference('Material.count') { @ingestor.write(@user, @portal) }
    end
    assert_equal @portal, @ingestor.materials.first.content_provider
    assert_equal({ added: 0, rejected: 1 }, @ingestor.stats[:content_providers])
    assert_equal 1, @ingestor.processed
    assert_equal 1, @ingestor.added
    assert_equal 0, @ingestor.updated
    assert_equal 0, @ingestor.rejected
    assert_includes @ingestor.messages.join("\n"), 'Title'
    assert_includes @ingestor.messages.join("\n"), 'use the source content provider instead'
  end

  test 'a referenced provider is created even when its material fails validation' do
    stub_request(:get, @provider[:url]).to_return(body: '')
    provider = @ingestor.find_provider_by_extracted_urls([@provider])
    add_material(provider, description: nil)

    assert_difference('ContentProvider.count') do
      assert_no_difference('Material.count') { @ingestor.write(@user, @portal) }
    end
    assert_equal 1, @ingestor.stats[:content_providers][:added]
    assert_equal 1, @ingestor.rejected
    assert_equal 0, @ingestor.added
  end

  private

  def add_material(provider, **attributes)
    @ingestor.add_material({ title: 'Imported material', description: 'Training material',
                             url: 'https://materials.example.org/one', content_provider: provider }.merge(attributes))
  end
end
