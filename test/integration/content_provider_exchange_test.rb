require 'test_helper'

class ContentProviderExchangeTest < ActionDispatch::IntegrationTest
  test 'rendered event and material exports recreate providers with their exchanged metadata and real images only' do
    mock_images
    portal = content_providers(:portal_provider)
    user = users(:regular_user)

    [false, true].each do |with_image|
      provider = ContentProvider.create!(
        title: "Exchange provider #{with_image}", url: "https://provider.example.org/#{with_image}",
        description: 'Provider training & resources', keywords: ['training', 'FAIR data'], user: user,
        image_url: with_image ? 'http://example.com/logo.png' : nil
      )
      provider_url = content_provider_url(provider)
      get provider_url
      assert_response :success
      provider_html = response.body
      if with_image
        assert_select 'meta[property="og:image"]', count: 1
        image_url = Nokogiri::HTML(provider_html).at('meta[property="og:image"]')['content']
        stub_request(:get, image_url).to_return(body: Rails.root.join('test/fixtures/files/image.png').read,
                                               headers: { 'Content-Type' => 'image/png' })
      else
        assert_select 'meta[property="og:image"]', count: 0
        assert_select 'meta[name="twitter:image"]', count: 0
        assert_select 'img.medium-avatar', count: 1
      end

      resources = [Event.new, Event.new(event_types: ['workshops_and_courses'], start: 1.day.from_now,
                                        end: 2.days.from_now), Material.new]
      exports = resources.each_with_index.map do |resource, index|
        klass = resource.class
        resource.assign_attributes(
          title: "Exchange #{klass.name} #{index} #{with_image}",
          url: "https://resources.example.org/#{klass.name}/#{index}/#{with_image}",
          description: 'Training resource', user: user, content_provider: provider
        )
        resource.save!
        export_url = klass == Event ? event_url(resource) : material_url(resource)
        get export_url
        assert_response :success
        stub_request(:get, export_url).to_return(body: response.body)
        # Existing course ingestion also extracts and rejects the unnamed nested instance.
        expected_rejections = resource.is_a?(Event) && resource.event_types.include?('workshops_and_courses') ? 1 : 0
        [klass, export_url, resource.url, expected_rejections]
      end
      expected = provider.attributes.slice('title', 'url', 'description', 'keywords')
      provider.destroy!
      assert_nil ContentProvider.find_by(url: expected['url'])
      stub_request(:get, provider_url).to_return(body: provider_html)
      homepage_request = stub_request(:get, expected['url']).to_return(
        body: '<meta property="og:description" content="Homepage metadata must not replace registry metadata">'
      )

      exports.each_with_index do |(klass, export_url, resource_url, expected_rejections), index|
        ingestor = Ingestors::BioschemasIngestor.new
        ingestor.source = Source.new(url: export_url, method: 'bioschemas', content_provider: portal)
        ingestor.read(export_url)
        ingestor.resolve_providers
        assert_empty ingestor.messages.grep(/error occurred/)
        assert_equal 1 + expected_rejections, ingestor.ingested
        assert_equal 1, ingestor.providers.size
        candidate = ingestor.providers.first
        assert_equal expected, candidate.attributes.slice(*expected.keys)
        assert_equal with_image ? image_url : nil, candidate.image_url
        assert candidate.new_record?

        assert_difference('ContentProvider.count', index.zero? ? 1 : 0) do
          assert_difference("#{klass.name}.count") { ingestor.write(user) }
        end
        imported = klass.find_by!(url: resource_url)
        assert_equal expected, imported.content_provider.attributes.slice(*expected.keys)
        assert_equal candidate.url, imported.content_provider.url
        assert_equal with_image, imported.content_provider.image?
        assert_equal 1, ingestor.added
        assert_equal expected_rejections, ingestor.rejected
        assert_equal 0, ingestor.stats[:content_providers][:rejected]
        assert_not_requested homepage_request
      end
    end
  end
end
