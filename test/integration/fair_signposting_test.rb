require 'test_helper'

class FairSignpostingTest < ActionDispatch::IntegrationTest
  RO_CRATE_PROFILE = 'https://w3id.org/ro/crate'.freeze
  SIGNPOSTING_RELS = %w[describedby cite-as author license type item].freeze

  test 'fair signposting for material' do
    material = materials(:good_material)
    material.authors.create!(name: 'Ada Lovelace', orcid: '0000-0002-1825-0097')
    material.authors.create!(name: 'Charles Babbage')

    get material_path(material)

    assert_response :success
    assert_match(/rel="preload"/, response.headers['Link'], 'Rails preload links should be kept')
    assert_match(/\A<[^>]*>\s*;\s*rel="describedby"/, response.headers['Link'], 'Signposting links should come first')
    links = parse_link_header
    assert_equal 8, links.size
    assert_link(links, material_url(material, format: :jsonld), rel: 'describedby', type: 'application/ld+json',
                                                                profile: 'https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE')
    assert_link(links, ro_crate_metadata_material_url(material), rel: 'describedby', type: 'application/ld+json',
                                                                 profile: RO_CRATE_PROFILE)
    assert_link(links, material_url(material, format: :json_api), rel: 'describedby', type: 'application/vnd.api+json')
    assert_link(links, 'http://dx.doi.ac.uk/2q3093032', rel: 'cite-as')
    assert_link(links, 'https://orcid.org/0000-0002-1825-0097', rel: 'author')
    assert_link(links, 'http://spdx.org/licenses/CC-BY-4.0', rel: 'license')
    assert_link(links, 'https://schema.org/LearningResource', rel: 'type')
    assert_link(links, 'https://schema.org/AboutPage', rel: 'type')

    html_links = Nokogiri::HTML(response.body).css('head link[rel="describedby"]').map { |l| l['href'] }
    assert_includes html_links, ro_crate_metadata_material_url(material)
  end

  test 'fair signposting for material without doi, licence or authors' do
    material = materials(:bad_material)

    get material_path(material)

    assert_response :success
    links = parse_link_header
    assert_equal 5, links.size
    assert_empty(links.select { |l| %w[cite-as author license].include?(l[:rel]) })
  end

  test 'doi rewritten to https://doi.org/ in cite-as and ro-crate' do
    material = materials(:biojs)
    material.update_column(:doi, 'http://dx.doi.org/10.1109/SEAA.2009.59')

    get material_path(material)

    assert_response :success
    assert_link(parse_link_header, 'https://doi.org/10.1109/SEAA.2009.59', rel: 'cite-as')

    get ro_crate_metadata_material_path(material)

    main = JSON.parse(response.body)['@graph'].detect { |e| e['@id'] == material.url }
    assert_equal 'https://doi.org/10.1109/SEAA.2009.59', main['identifier']
  end

  test 'fair signposting for event' do
    event = events(:one)

    get event_path(event)

    assert_response :success
    links = parse_link_header
    assert_equal 5, links.size
    assert_link(links, event_url(event, format: :jsonld), rel: 'describedby', type: 'application/ld+json',
                                                          profile: 'https://bioschemas.org/profiles/Course/1.0-RELEASE')
    assert_link(links, ro_crate_metadata_event_url(event), rel: 'describedby', type: 'application/ld+json',
                                                           profile: RO_CRATE_PROFILE)
    assert_link(links, 'https://schema.org/Course', rel: 'type')
  end

  test 'no fair signposting on index' do
    get materials_path

    assert_response :success
    assert_empty parse_link_header
  end

  test 'detached ro-crate for material' do
    material = materials(:good_material)

    get ro_crate_metadata_material_path(material)

    assert_response :success
    assert response.content_type.start_with?(%(application/ld+json; profile="#{RO_CRATE_PROFILE}"))
    crate = JSON.parse(response.body)
    assert_equal 'https://w3id.org/ro/crate/1.3/context', crate['@context']
    entities = crate['@graph'].index_by { |e| e['@id'] }

    descriptor = entities['ro-crate-metadata.json']
    assert_equal 'https://w3id.org/ro/crate/1.3', descriptor.dig('conformsTo', '@id')
    assert_equal material_url(material), descriptor.dig('about', '@id')

    root = entities[material_url(material)]
    assert_equal crate['@graph'][1], root, 'Root Data Entity should follow the metadata descriptor'
    assert_equal 'Dataset', root['@type']
    assert_equal 'Training Material Example', root['name']
    assert_equal 'This is a Training Material produced by an example organization', root['description']
    assert root['datePublished'].present?
    assert_equal 'http://spdx.org/licenses/CC-BY-4.0', root.dig('license', '@id')
    assert_equal 'Creative Commons Attribution 4.0 International',
                 entities['http://spdx.org/licenses/CC-BY-4.0']['name']
    assert_equal root_url, root.dig('publisher', '@id')
    assert_nil root['conformsTo']

    # The material itself, at its external URL, is the main entity and a part of the crate
    assert_equal({ '@id' => 'http://training.com/trainers/1359023' }, root['mainEntity'])
    assert_equal({ '@id' => 'http://training.com/trainers/1359023' }, root['hasPart'])
    main = entities['http://training.com/trainers/1359023']
    assert_equal 'LearningResource', main['@type']
    assert_equal 'Training Material Example', main['name']
    assert_equal 'This is a Training Material produced by an example organization', main['description']
    assert_nil main['url']
    assert_equal 'http://spdx.org/licenses/CC-BY-4.0', main.dig('license', '@id')
    assert_equal 'https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE', main.dig('conformsTo', '@id')
    assert_equal 'Profile', entities['https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE']['@type']
    assert_equal root_url, main.dig('sdPublisher', '@id')
    assert_nil main['dct:conformsTo']
    assert_nil main['@context']
    assert_equal 1, crate['@graph'].count { |e| e['name'] == 'Goblet' }, 'Provider should be flattened once'

    assert_flattened(crate)
  end

  test 'local main entity and no part in detached ro-crate for material without a valid url' do
    material = materials(:good_material)
    material.update_column(:url, 'Not really a valid URL.com')

    get ro_crate_metadata_material_path(material)

    assert_response :success
    crate = JSON.parse(response.body)
    entities = crate['@graph'].index_by { |e| e['@id'] }
    root = entities[material_url(material)]
    assert_nil root['hasPart']
    main = entities[root.dig('mainEntity', '@id')]
    assert main['@id'].start_with?('#')
    assert_equal 'LearningResource', main['@type']
    assert_equal 'Not really a valid URL.com', main['url']
    assert_flattened(crate)
  end

  test 'detached ro-crate for event' do
    event = events(:one)

    get ro_crate_metadata_event_path(event)

    assert_response :success
    crate = JSON.parse(response.body)
    entities = crate['@graph'].index_by { |e| e['@id'] }
    root = entities[event_url(event)]
    assert_equal 'Dataset', root['@type']
    assert_equal RoCrateExport::DetachedCrate::NO_LICENCE, root['license']

    # The event is the main entity, but not a data entity
    assert_equal({ '@id' => 'http://example.com/cool-event' }, root['mainEntity'])
    assert_nil root['hasPart']
    main = entities['http://example.com/cool-event']
    assert_equal 'Course', main['@type']
    assert_equal 'event one', main['name']
    RoCrateExport::DetachedCrate::UNDEFINED_PROPERTIES.each do |property|
      assert_nil main[property]
    end

    assert_flattened(crate)
  end

  test 'detached ro-crate by content negotiation' do
    material = materials(:good_material)

    get material_path(material), headers: { 'Accept' => %(application/ld+json; profile="#{RO_CRATE_PROFILE}") }

    assert_response :success
    assert_equal 'ro-crate-metadata.json', JSON.parse(response.body)['@graph'].first['@id']
  end

  test 'bioschemas json-ld without ro-crate profile' do
    material = materials(:good_material)

    get material_path(material), headers: { 'Accept' => 'application/ld+json' }

    assert_response :success
    assert_equal 'LearningResource', JSON.parse(response.body)['@type']
  end

  test 'no ro-crate for material from unverified user' do
    material = materials(:good_material)
    material.update_column(:user_id, users(:unverified_user).id)

    get ro_crate_metadata_material_path(material)

    assert_response :forbidden
  end

  private

  # Signposting links in the Link header, ignoring others such as asset preload hints.
  def parse_link_header
    links = response.headers['Link'].to_s.split(/,\s*(?=<)/).map { |link| parse_link(link) }
    links.select { |link| SIGNPOSTING_RELS.include?(link[:rel]) }
  end

  def parse_link(link)
    url, *params = link.split(/\s*;\s*/)
    params.map { |p| p.split('=', 2) }.to_h { |k, v| [k.to_sym, v&.delete('"')] }.merge(url: url[1..-2])
  end

  def assert_link(links, url, **attributes)
    expected = attributes.merge(url:)
    assert links.include?(expected), "Expected link #{expected.inspect} in:\n#{links.map(&:inspect).join("\n")}"
  end

  # Every entity is at the top level of the @graph, and other entities are only referenced by @id.
  def assert_flattened(crate)
    ids = crate['@graph'].map { |e| e['@id'] }
    assert_equal ids.uniq, ids
    crate['@graph'].each do |entity|
      assert entity['@type'].present?, "#{entity['@id']} has no @type"
      entity.except('@id', '@type').each_value do |value|
        Array(value).grep(Hash).each do |ref|
          assert_equal ['@id'], ref.keys, "Nested entity in #{entity['@id']}: #{ref.inspect}"
        end
      end
    end
  end
end
