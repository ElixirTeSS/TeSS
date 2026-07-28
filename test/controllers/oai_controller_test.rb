require 'test_helper'

class OaiControllerTest < ActionDispatch::IntegrationTest
  setup do
    @material = materials(:good_material)
    @event = events(:two)
    @user = users(:regular_user)
    @material.user_id = @user.id
    @material.save!
    @ns = {
      'oai' => 'http://www.openarchives.org/OAI/2.0/',
      'dc' => 'http://purl.org/dc/elements/1.1/',
      'sdo' => 'http://schema.org/',
      'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
    }
  end

  test 'should get endpoint' do
    get '/oai-pmh'
    assert_response :success
    assert_includes @response.body, 'xml-stylesheet'
  end

  test 'OAI Identify verb returns expected repository info' do
    get '/oai-pmh', params: { verb: 'Identify' }
    assert_response :success

    parsed = Nokogiri::XML(@response.body)
    assert_equal '2.0', parsed.at_xpath('//oai:protocolVersion', @ns).text
  end

  test 'OAI ListMetadataFormats verb returns expected repository info' do
    get '/oai-pmh', params: { verb: 'ListMetadataFormats' }
    assert_response :success

    parsed = Nokogiri::XML(@response.body)
    prefixes = parsed.xpath('//oai:ListMetadataFormats/oai:metadataFormat/oai:metadataPrefix', @ns).map(&:text)
    assert_includes prefixes, 'oai_dc'
    assert_includes prefixes, 'rdf'
  end

  test 'OAI ListSets exposes sets for materials and events' do
    get '/oai-pmh', params: { verb: 'ListSets' }
    assert_response :success

    parsed = Nokogiri::XML(@response.body)
    set_specs = parsed.xpath('//oai:ListSets/oai:set/oai:setSpec', @ns).map(&:text)

    assert_includes set_specs, 'materials'
    assert_includes set_specs, 'events'
  end

  test 'OAI ListRecords returns material in oai_dc format' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'oai_dc' }
    assert_response :success

    parsed = Nokogiri::XML(@response.body)
    titles = parsed.xpath('//dc:title', @ns).map(&:text)
    assert_includes titles, @material.title

    subjects = parsed.xpath('//dc:subject', @ns).map(&:text)
    @material.keywords.each { |kw| assert_includes subjects, kw }

    identifiers = parsed.xpath('//dc:identifier', @ns).map(&:text)
    assert_includes identifiers, @material.doi
  end

  test 'OAI ListRecords returns event in oai_dc format' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'oai_dc' }
    assert_response :success

    parsed = Nokogiri::XML(@response.body)
    event_records = parsed.xpath("//oai:record[contains(oai:header/oai:identifier, 'events/') ]", @ns)

    refute_empty event_records
    event_titles = event_records.xpath('.//dc:title', @ns).map(&:text)
    assert_includes event_titles, @event.title

    event_types = event_records.xpath('.//dc:type', @ns).map(&:text)
    assert_includes event_types, 'http://purl.org/dc/dcmitype/Event'
    assert_includes event_types, 'https://schema.org/Event'
  end

  test 'OAI-PMH endpoint respects current space' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'oai_dc' }
    parsed = Nokogiri::XML(@response.body)
    titles = parsed.xpath('//dc:title', @ns).map(&:text)
    assert_includes titles, materials(:training_material).title
    assert_includes titles, materials(:plant_space_material).title

    plant_space = spaces(:plants)
    with_host(plant_space.host) do
      get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'oai_dc' }
      parsed = Nokogiri::XML(@response.body)
      titles = parsed.xpath('//dc:title', @ns).map(&:text)
      refute_includes titles, materials(:training_material).title
      assert_includes titles, materials(:plant_space_material).title
    end
  end

  test 'OAI ListRecords returns material in rdf format' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'rdf' }
    assert_response :success

    parsed = Nokogiri::XML(@response.body)

    names = parsed.xpath('//sdo:LearningResource/sdo:name', @ns).map(&:text)
    assert_includes names, 'Training Material Example'

    keywords = parsed.xpath('//sdo:LearningResource/sdo:keywords', @ns).map(&:text)
    assert_includes keywords, 'good'
  end

  test 'OAI ListRecords returns event in rdf format' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'rdf' }
    assert_response :success

    parsed = Nokogiri::XML(@response.body)

    event_names = parsed.xpath('//sdo:Event/sdo:name', @ns).map(&:text)
    assert_includes event_names, @event.title

    event_urls = parsed.xpath('//sdo:Event/sdo:url/@rdf:resource', @ns).map(&:value)
    assert_includes event_urls, @event.url
  end

  test 'OAI ListRecords returns only visible materials' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'rdf' }
    assert_response :success

    parsed = Nokogiri::XML(@response.body)

    assert_includes parsed.xpath('//sdo:name', @ns).map(&:text), 'Training Material Example'

    @material.update!(visible: false)

    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'rdf' }
    assert_response :success
    parsed = Nokogiri::XML(@response.body)
    refute_includes parsed.xpath('//sdo:name', @ns).map(&:text), 'Training Material Example'
  end

  test 'OAI ListRecords resumes with resumption token' do
    user = users(:regular_user)
    base_count = Event.where(visible: true).count + Material.where(visible: true).count
    records_needed = [0, 105 - base_count].max

    records_needed.times do |i|
      Event.create!(title: "Paged event #{i}", url: "https://example.org/paged-events/#{i}", user: user)
    end

    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'rdf' }
    assert_response :success

    parsed = Nokogiri::XML(@response.body)
    token = parsed.at_xpath('//oai:ListRecords/oai:resumptionToken', @ns)&.text
    assert token.present?, 'Expected non-empty resumptionToken for paginated result set'

    get '/oai-pmh', params: { verb: 'ListRecords', resumptionToken: token }
    assert_response :success

    parsed = Nokogiri::XML(@response.body)
    refute parsed.at_xpath("//oai:error[@code='cannotDisseminateFormat']", @ns)
    assert_operator parsed.xpath('//oai:ListRecords/oai:record', @ns).length, :>, 0
  end

  test 'OAI resumption token does not repeat the last returned record at a same-timestamp page boundary' do
    user = users(:regular_user)
    boundary_space = Space.create!(title: 'Boundary Space', host: 'boundary-space.example', user: user)
    boundary_time = Time.utc(2026, 7, 28, 12, 0, 0)

    records = 101.times.map do |i|
      material = Material.create!(title: "Boundary material #{i}",
                                  description: "Boundary material #{i}",
                                  url: "https://example.org/boundary-material/#{i}",
                                  user: user,
                                  visible: true,
                                  space: boundary_space)
      material.update_columns(updated_at: boundary_time, created_at: boundary_time)
      material
    end

    with_host(boundary_space.host) do
      get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'rdf' }
      assert_response :success

      parsed = Nokogiri::XML(@response.body)
      first_page_titles = parsed.xpath('//sdo:LearningResource/sdo:name', @ns).map(&:text)
      assert_equal 100, first_page_titles.length

      token = parsed.at_xpath('//oai:ListRecords/oai:resumptionToken', @ns)&.text
      assert token.present?, 'Expected non-empty resumptionToken for the first page'

      get '/oai-pmh', params: { verb: 'ListRecords', resumptionToken: token }
      assert_response :success

      parsed = Nokogiri::XML(@response.body)
      second_page_titles = parsed.xpath('//sdo:LearningResource/sdo:name', @ns).map(&:text)
      refute_includes second_page_titles, first_page_titles.last
      assert_includes second_page_titles, records.last.title
    end
  end
end
