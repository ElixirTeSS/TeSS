require 'test_helper'

class ProviderIngestionTest < ActiveSupport::TestCase
  setup do
    @ingestor = Ingestors::BioschemasIngestor.new
    @portal = content_providers(:portal_provider)
    @user = users(:scraper_user)
    @ingestor.source = Source.new(content_provider: @portal, method: 'bioschemas')
    @provider = { name: 'Imported provider', url: 'https://provider.example.org' }
    stub_request(:get, @provider[:url]).to_return(body: '')
  end

  test 'provider references survive normalization without resolution or requests' do
    material = add_material(providers: [@provider])
    assert_equal [@provider], material.providers
    assert_nil material.content_provider
    assert_empty @ingestor.providers
    assert_not_requested :get, @provider[:url]
  end

  test 'provider identity uses URL and excludes nodes and candidates without URLs' do
    existing = content_providers(:organisation_provider)
    stub_request(:get, existing.url).to_return(body: '')
    candidates = [
      { name: "ELIXIR #{nodes(:good).name}", url: 'https://node.example.org' },
      { name: existing.title },
      @provider,
      { name: 'A different name', url: existing.url }
    ]
    assert_equal existing.url, ingest(candidates).url
    assert_not_requested :get, @provider[:url]

    assert_nil ingest(candidates.first(2))
    different_url = @provider.merge(name: existing.title)
    provider = ingest([different_url])
    assert provider.new_record?
    assert_equal existing.title, provider.title
    assert_nil ContentProvider.check_exists(provider)
  end

  test 'provider selection does not depend on metadata richness' do
    other = { name: 'Other provider', url: 'https://other-provider.example.org' }
    request = stub_request(:get, other[:url]).to_return(body: '<meta property="og:description" content="Rich metadata">')
    assert_equal @provider[:url], ingest([@provider, other]).url
    assert_not_requested request
  end

  test 'preview resolution merges all event and material references and assigns providers without persisting them' do
    registry_url = 'https://registry.example.org/content_providers/provider'
    @ingestor.source.url = 'https://registry.example.org/sitemap.txt'
    registry = stub_request(:get, registry_url).to_return(
      body: '<meta property="og:description" content="Registry description"><meta name="keywords" content="training, FAIR data">'
    )
    first = add_material(providers: [@provider.merge(name: nil)])
    second = add_material(providers: [@provider.merge(see_also: [registry_url])])
    @ingestor.add_event(title: 'Imported event', url: 'https://events.example.org/1', providers: [@provider])
    event = @ingestor.events.last
    assert_no_difference(['ContentProvider.count', 'PublicActivity::Activity.count']) do
      @ingestor.resolve_providers
    end

    provider = @ingestor.providers.first
    assert_same provider, event.content_provider
    assert_same provider, first.content_provider
    assert_same provider, second.content_provider
    assert provider.new_record?
    assert_equal @provider[:name], provider.title
    assert_equal 'Registry description', provider.description
    assert_equal ['training', 'FAIR data'], provider.keywords
    assert_not_requested :get, @provider[:url]
    assert_requested registry, times: 1
  end

  test 'writing fetches each referenced URL once and assigns resolved providers' do
    existing = owned_provider(url: 'https://existing-provider.example.org', last_scraped_by_source: sources(:first_source))
    stub_request(:get, existing.url).to_return(body: '')
    material = add_material(providers: [@provider])
    shared_material = add_material(providers: [@provider])
    existing_material = add_material(providers: [{ url: existing.url }])
    @ingestor.add_event(title: 'Imported event', url: 'https://events.example.org/1', providers: [@provider])
    event = @ingestor.events.last

    assert_no_difference(['Event.count', 'Material.count']) do
      assert_difference(['ContentProvider.count', 'PublicActivity::Activity.count']) { @ingestor.write_providers(@user) }
    end

    provider = ContentProvider.find_by!(url: @provider[:url])
    assert_equal provider, material.content_provider
    assert_same material.content_provider, shared_material.content_provider
    assert_same material.content_provider, event.content_provider
    assert_equal existing, existing_material.content_provider
    assert_equal 3.days.ago.to_date, existing.reload.last_scraped
    assert_equal({ processed: 2, added: 1, updated: 0, rejected: 0 }, @ingestor.stats[:content_providers])
    assert_requested :get, @provider[:url], times: 1
    assert_requested :get, existing.url, times: 1
  end

  test 'writing assigns nil to all resources referencing a rejected provider' do
    material = add_material(providers: [{ url: @provider[:url] }])
    shared_material = add_material(providers: [{ url: @provider[:url] }])
    assert_no_difference('ContentProvider.count') { @ingestor.write_providers(@user) }

    assert_nil material.content_provider
    assert_nil shared_material.content_provider
    assert_equal 1, @ingestor.stats[:content_providers][:processed]
    assert_equal 1, @ingestor.stats[:content_providers][:rejected]
  end

  test 'non-portals skip provider resolution and writes without assigning resources' do
    @ingestor.source.content_provider = content_providers(:organisation_provider)
    material = add_material(providers: [@provider])

    assert_no_difference('ContentProvider.count') do
      @ingestor.resolve_providers
      @ingestor.write_providers(@user)
    end
    assert_empty @ingestor.providers
    assert_nil material.content_provider
    assert_equal 0, @ingestor.stats[:content_providers][:processed]
    assert_not_requested :get, @provider[:url]
  end

  test 'provider fetching runs only once per referenced URL' do
    3.times { add_material(providers: [@provider]) }
    @ingestor.resolve_providers
    assert_requested :get, @provider[:url], times: 1
    assert_equal 1, @ingestor.providers.size
  end

  test 'unavailable or empty registry metadata falls back to the homepage with diagnostics' do
    @ingestor.source.url = 'https://registry.example.org/sitemap.txt'
    failed_url = 'https://registry.example.org/failed'
    empty_url = 'https://registry.example.org/empty'
    stub_request(:get, failed_url).to_timeout
    stub_request(:get, empty_url).to_return(body: '')
    stub_request(:get, @provider[:url]).to_return(body: '<meta property="og:description" content="Homepage description">')
    provider = ingest([@provider.merge(see_also: [@provider[:url], 'not a URL', failed_url, empty_url])])

    assert_equal 'Homepage description', provider.description
    assert_includes @ingestor.messages.join("\n"), failed_url
    assert_includes @ingestor.messages, 'Invalid content provider metadata URL: not a URL'
    assert_requested :get, empty_url, times: 1
    assert_requested :get, @provider[:url], times: 1
  end

  test 'enrichment only applies automatic parsing supported by providers' do
    stub_request(:get, @provider[:url]).to_return(body: '<meta property="og:description" content="Training for professors">')
    with_settings(feature: { auto_parse_vars: %w[target_audience keywords] }) do
      @ingestor.stub(:auto_parse, ->(field, _description) { field == :keywords ? ['training'] : [] }) do
        provider = ingest([@provider])
        assert_equal ['training'], provider.keywords
        refute provider.respond_to?(:target_audience)
      end
    end
  end

  test 'metadata omits blanks and invalid image URLs without losing keywords' do
    [nil, '', '/relative-logo.png', 'javascript:alert(1)', 'not a URL'].each do |image|
      image_tag = %(<meta property="og:image" content="#{image}">) unless image.nil?
      stub_request(:get, @provider[:url]).to_return(
        body: %(<meta property="og:description" content=" ">#{image_tag}<meta name="keywords" content="training, FAIR data">)
      )
      assert_equal({ keywords: ['training', 'FAIR data'] }, @ingestor.send(:scrape_og_metadata, @provider[:url]))
    end
    stub_request(:get, @provider[:url]).to_return(body: '')
    assert_empty @ingestor.send(:scrape_og_metadata, @provider[:url])
  end

  test 'metadata retains a valid absolute image URL and description' do
    stub_request(:get, @provider[:url]).to_return(
      body: '<meta property="og:description" content="Training"><meta property="og:image" content="https://images.example.org/logo.png">'
    )
    assert_equal({ description: 'Training', image_url: 'https://images.example.org/logo.png' },
                 @ingestor.send(:scrape_og_metadata, @provider[:url]))
  end

  test 'metadata read failures are reported and preserve fallback' do
    failed_url = 'https://registry.example.org/failed'
    stub_request(:get, @provider[:url]).to_return(body: '<meta property="og:description" content="Homepage description">')
    errors = [
      URI::InvalidURIError.new('invalid URI'), IOError.new('read failed'), SocketError.new('lookup failed'),
      Errno::ECONNRESET.new, Net::ReadTimeout.new, OpenSSL::SSL::SSLError.new('TLS failed'),
      OpenURI::HTTPRedirect.new('redirect failed', StringIO.new, 'https://redirect.example.org')
    ]
    errors.each do |error|
      original_open_url = @ingestor.method(:open_url)
      @ingestor.stub(:open_url, ->(url) { url == failed_url ? raise(error) : original_open_url.call(url) }) do
        assert_equal({ description: 'Homepage description' },
                     @ingestor.send(:fetch_provider_metadata, [failed_url, @provider[:url]]))
      end
      assert_includes @ingestor.messages.last, "Couldn't read content provider metadata from #{failed_url}: #{error.class}:"
    end
  end

  test 'filtered resources do not cause provider resolution requests or writes' do
    add_material(providers: [@provider])
    @ingestor.source.source_filters = [SourceFilter.new(mode: 'block', property: 'title', value: 'Imported material')]
    ContentProvider.stub(:exists?, ->(*) { flunk 'filtered providers must not be resolved' }) do
      assert_no_difference('ContentProvider.count') { @ingestor.write(@user) }
    end
    assert_empty @ingestor.providers
    assert_not_requested :get, @provider[:url]
  end

  test 'provider rejection uses the portal and does not inflate resource statistics' do
    add_material(providers: [{ url: @provider[:url] }])
    assert_no_difference('ContentProvider.count') do
      assert_difference('Material.count') { @ingestor.write(@user) }
    end
    assert_equal @portal, @ingestor.materials.first.content_provider
    assert_equal({ processed: 1, added: 0, updated: 0, rejected: 1 }, @ingestor.stats[:content_providers])
    assert_equal 1, @ingestor.processed
    assert_equal 1, @ingestor.added
    assert_equal 0, @ingestor.rejected
    assert_includes @ingestor.messages.join("\n"), 'Title'
    assert_includes @ingestor.messages.join("\n"), 'use the source content provider instead'
  end

  test 'a provider is created even when its referenced material fails validation' do
    add_material(providers: [@provider], description: nil)
    assert_difference('ContentProvider.count') do
      assert_no_difference('Material.count') { @ingestor.write(@user) }
    end
    assert_equal 1, @ingestor.stats[:content_providers][:added]
    assert_equal 1, @ingestor.rejected
  end

  test 'created providers record freshness and responsibility without changing source persistence' do
    use_source(sources(:first_source))
    add_material(providers: [@provider])
    @ingestor.write(@user)
    provider = ContentProvider.find_by!(url: @provider[:url])
    assert provider.scraper_record
    assert_equal Date.current, provider.last_scraped
    assert_equal @ingestor.source, provider.last_scraped_by_source
    assert_equal 1, @ingestor.stats[:content_providers][:added]
  end

  test 'the responsible source updates metadata and logs the importing actor' do
    source = sources(:first_source)
    use_source(source)
    provider = owned_provider(description: 'Old description', keywords: ['old'], last_scraped_by_source: source)
    stub_request(:get, @provider[:url]).to_return(
      body: '<meta property="og:description" content="New description"><meta name="keywords" content="new">'
    )
    add_material(providers: [@provider])
    assert_no_difference('ContentProvider.count') { @ingestor.write(@user) }

    assert_equal 'New description', provider.reload.description
    assert_equal ['new'], provider.keywords
    assert_equal Date.current, provider.last_scraped
    assert_equal source, provider.last_scraped_by_source
    assert_equal 1, @ingestor.stats[:content_providers][:updated]
    activity = PublicActivity::Activity.find_by!(trackable: provider, key: 'content_provider.update')
    assert_equal @user, activity.owner
    assert_requested :get, @provider[:url], times: 1
  end

  test 'rename-only updates preserve unsupplied metadata and administrative fields' do
    source = sources(:first_source)
    use_source(source)
    provider = owned_provider(description: 'Kept description', keywords: ['kept'], title: 'Old name',
                              content_provider_type: 'Project', node: nodes(:good), contact: 'Curator',
                              last_scraped_by_source: source)
    add_material(providers: [@provider])
    @ingestor.write(@user)
    assert_equal @provider[:name], provider.reload.title
    assert_equal 'Kept description', provider.description
    assert_equal ['kept'], provider.keywords
    assert_equal 'Project', provider.content_provider_type
    assert_equal nodes(:good), provider.node
    assert_equal 'Curator', provider.contact
  end

  test 'empty or failed metadata fetches preserve stored values and do not log freshness-only updates' do
    source = sources(:first_source)
    use_source(source)
    provider = owned_provider(description: 'Kept description', keywords: ['kept'], last_scraped_by_source: source)
    provider.update_columns(image_url: 'https://images.example.org/kept.png', image_file_name: 'kept.png')
    stub_request(:get, @provider[:url]).to_timeout
    add_material(providers: [@provider])
    assert_no_difference("PublicActivity::Activity.where(trackable_type: 'ContentProvider', key: 'content_provider.update').count") do
      @ingestor.write(@user)
    end
    assert_equal 'Kept description', provider.reload.description
    assert_equal ['kept'], provider.keywords
    assert_equal 'https://images.example.org/kept.png', provider.image_url
    assert_equal Date.current, provider.last_scraped
    assert_equal 1, @ingestor.stats[:content_providers][:updated]
    assert_includes @ingestor.messages.join("\n"), "Couldn't read content provider metadata"
  end

  test 'a less complete source cannot take over or refresh freshness' do
    owner = sources(:first_source)
    use_source(sources(:second_source))
    provider = owned_provider(description: 'Owner description', keywords: %w[one two], last_scraped_by_source: owner)
    stub_request(:get, @provider[:url]).to_return(body: '<meta property="og:description" content="A much longer incoming description">')
    add_material(providers: [@provider])
    @ingestor.write(@user)
    assert_equal owner, provider.reload.last_scraped_by_source
    assert_equal 'Owner description', provider.description
    assert_equal 3.days.ago.to_date, provider.last_scraped
    assert_equal 1, @ingestor.stats[:content_providers][:processed]
    assert_equal 0, @ingestor.stats[:content_providers][:updated]
    assert_equal provider, @ingestor.materials.first.content_provider
  end

  test 'richer metadata permits takeover and providers without responsibility can be claimed' do
    owner = sources(:first_source)
    use_source(sources(:second_source))
    provider = owned_provider(last_scraped_by_source: owner)
    stub_request(:get, @provider[:url]).to_return(
      body: '<meta property="og:description" content="Richer description"><meta name="keywords" content="richer">'
    )
    add_material(providers: [@provider])
    @ingestor.write(@user)
    assert_equal @ingestor.source, provider.reload.last_scraped_by_source
    assert_equal 'Richer description', provider.description

    unclaimed = owned_provider(url: 'https://unclaimed.example.org', last_scraped_by_source: nil)
    @ingestor = Ingestors::BioschemasIngestor.new
    use_source(sources(:second_source))
    stub_request(:get, unclaimed.url).to_return(body: '')
    add_material(providers: [@provider.merge(url: unclaimed.url)])
    @ingestor.write(@user)
    assert_equal @ingestor.source, unclaimed.reload.last_scraped_by_source
  end

  test 'description takeover requires strictly more than one and a half times the existing length' do
    owner = sources(:first_source)
    provider = owned_provider(description: 'abcdefghij', last_scraped_by_source: owner)
    [15, 16].each do |length|
      @ingestor = Ingestors::BioschemasIngestor.new
      use_source(sources(:second_source))
      stub_request(:get, @provider[:url]).to_return(body: %(<meta property="og:description" content="#{'x' * length}">))
      add_material(providers: [@provider])
      @ingestor.write(@user)
      assert_equal(length == 16 ? @ingestor.source : owner, provider.reload.last_scraped_by_source)
    end
  end

  test 'locked metadata cannot win or block takeover and is not written' do
    owner = sources(:first_source)
    use_source(sources(:second_source))
    provider = owned_provider(description: 'Owner description', last_scraped_by_source: owner)
    FieldLock.create!(resource: provider, field: 'keywords')
    stub_request(:get, @provider[:url]).to_return(
      body: '<meta property="og:description" content="Owner description"><meta name="keywords" content="incoming">'
    )
    add_material(providers: [@provider])
    @ingestor.write(@user)
    assert_equal owner, provider.reload.last_scraped_by_source
    assert_empty provider.keywords

    provider.field_locks.destroy_all
    FieldLock.create!(resource: provider, field: 'description')
    @ingestor = Ingestors::BioschemasIngestor.new
    use_source(sources(:second_source))
    add_material(providers: [@provider])
    @ingestor.write(@user)
    assert_equal @ingestor.source, provider.reload.last_scraped_by_source
    assert_equal 'Owner description', provider.description
    assert_equal ['incoming'], provider.keywords
  end

  test 'uploaded images count as existing metadata and image locks exclude their aliases' do
    owner = sources(:first_source)
    use_source(sources(:second_source))
    provider = owned_provider(description: 'Owner description', last_scraped_by_source: owner)
    provider.update_columns(image_file_name: 'logo.png')
    incoming = ContentProvider.new(title: provider.title, url: provider.url, description: provider.description, keywords: ['incoming'])
    refute @ingestor.send(:responsible_for?, provider, incoming, @ingestor.source)
    provider.field_locks.create!(field: 'image')
    assert @ingestor.send(:responsible_for?, provider, incoming, @ingestor.source)
  end

  test 'failed updates preserve stored metadata and report rejection' do
    source = sources(:first_source)
    use_source(source)
    provider = owned_provider(description: 'Kept description', last_scraped_by_source: source)
    stub_request(:get, @provider[:url]).to_return(body: '<meta property="og:description" content="New description">')
    add_material(providers: [@provider])
    provider.errors.add(:description, 'is invalid')
    ContentProvider.stub(:check_exists, provider) do
      provider.stub(:save, false) { @ingestor.write(@user) }
    end
    assert_equal 'Kept description', provider.reload.description
    assert_equal provider, @ingestor.materials.first.content_provider
    assert_equal 1, @ingestor.stats[:content_providers][:rejected]
    assert_includes @ingestor.messages.join("\n"), 'Its existing details were kept.'
  end

  test 'new and existing provider metadata is visible in previews without persisting anything' do
    source = sources(:first_source)
    use_source(source)
    provider = owned_provider(description: 'Stored description', last_scraped_by_source: source)
    stub_request(:get, @provider[:url]).to_return(
      body: '<meta property="og:description" content="Preview description"><meta property="og:image" content="https://images.example.org/logo.png">'
    )
    material = add_material(providers: [@provider])
    assert_no_difference(['ContentProvider.count', 'PublicActivity::Activity.count']) do
      @ingestor.resolve_providers
    end
    incoming = @ingestor.providers.first
    assert_same incoming, material.content_provider
    assert_equal 'Preview description', incoming.description
    assert incoming.new_record?
    preview = Source.get_test_resource('content_providers', source.send(:deep_hashify, incoming), user: @user)
    assert_equal provider.id, preview.id
    assert_equal 'Preview description', preview.description
    assert_equal 'https://images.example.org/logo.png', preview.image_url
    assert_equal 'Stored description', provider.reload.description
    assert_equal 3.days.ago.to_date, provider.last_scraped
  end

  test 'explicit provider IDs still work without refreshing providers' do
    provider = owned_provider(description: 'Kept description', last_scraped_by_source: sources(:first_source))
    add_material(content_provider_id: provider.id)
    @ingestor.write(@user)
    assert_equal [provider.id], @ingestor.materials.map(&:content_provider_id)
    assert_equal 3.days.ago.to_date, provider.reload.last_scraped
    assert_equal 0, @ingestor.stats[:content_providers][:processed]
    assert_not_requested :get, provider.url
  end

  test 'URL-only references keep richer stored metadata when the source is not responsible' do
    provider = owned_provider(description: 'Stored description', last_scraped_by_source: sources(:first_source))
    stub_request(:get, provider.url).to_return(body: '')
    add_material(providers: [{ url: provider.url }])
    @ingestor.write(@user)
    assert_equal provider, @ingestor.materials.first.content_provider
    assert_equal 'Stored description', provider.reload.description
    assert_equal 3.days.ago.to_date, provider.last_scraped
    assert_equal({ processed: 1, added: 0, updated: 0, rejected: 0 }, @ingestor.stats[:content_providers])
    assert_requested :get, provider.url, times: 1
  end

  test 'URL-only references refresh providers when the source is responsible' do
    source = sources(:first_source)
    use_source(source)
    provider = owned_provider(description: 'Old description', last_scraped_by_source: source)
    stub_request(:get, provider.url).to_return(body: '<meta property="og:description" content="Refreshed description">')
    add_material(providers: [{ url: provider.url }])
    @ingestor.write(@user)
    assert_equal provider, @ingestor.materials.first.content_provider
    assert_equal 'Refreshed description', provider.reload.description
    assert_operator provider.last_scraped, :>, 3.days.ago.to_date
    assert_equal source, provider.last_scraped_by_source
    assert_equal({ processed: 1, added: 0, updated: 1, rejected: 0 }, @ingestor.stats[:content_providers])
    assert_requested :get, provider.url, times: 1
  end

  test 'explicit IDs can supply matching metadata without changing association precedence' do
    source = sources(:first_source)
    use_source(source)
    provider = owned_provider(last_scraped_by_source: source)
    other = { name: 'Other', url: 'https://other.example.org' }
    add_material(content_provider_id: provider.id, providers: [other, @provider.merge(name: 'Renamed')])
    @ingestor.write(@user)
    assert_equal provider.id, @ingestor.materials.first.content_provider_id
    assert_equal 'Renamed', provider.reload.title
    assert_not_requested :get, other[:url]
  end

  test 'generic provider references work for non-Bioschemas ingestors and are ignored for non-portals' do
    @ingestor = Ingestors::MaterialCsvIngestor.new
    @ingestor.source = Source.new(content_provider: @portal, method: 'material_csv')
    add_material(providers: [@provider])
    assert_difference('ContentProvider.count') { @ingestor.write(@user) }
    assert_equal @provider[:url], @ingestor.materials.first.content_provider.url

    @ingestor = Ingestors::MaterialCsvIngestor.new
    provider = content_providers(:organisation_provider)
    @ingestor.source = Source.new(content_provider: provider, method: 'material_csv')
    add_material(providers: [{ name: 'Ignored', url: 'https://ignored.example.org' }])
    assert_no_difference('ContentProvider.count') { @ingestor.write(@user) }
    assert_equal provider, @ingestor.materials.first.content_provider
    assert_not_requested :get, 'https://ignored.example.org'
  end

  private

  def ingest(candidates)
    material = add_material(providers: candidates)
    @ingestor.resolve_providers
    material.content_provider
  end

  def use_source(source)
    source.content_provider = @portal
    @ingestor.source = source
  end

  def owned_provider(**attributes)
    ContentProvider.create!({
      title: @provider[:name], url: @provider[:url], user: users(:regular_user),
      scraper_record: true, last_scraped: 3.days.ago.to_date
    }.merge(attributes))
  end

  def add_material(**attributes)
    @ingestor.add_material({
      title: 'Imported material', description: 'Training material',
      url: "https://materials.example.org/#{@ingestor.materials.size}"
    }.merge(attributes))
    @ingestor.materials.last
  end
end
