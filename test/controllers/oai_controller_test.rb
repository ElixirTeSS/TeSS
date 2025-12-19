require 'test_helper'

class OaiControllerTest < ActionDispatch::IntegrationTest
  setup do
    @material = materials(:good_material)
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

  test 'OAI ListRecords returns material in rdf format' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'rdf' }
    assert_response :success

    parsed = Nokogiri::XML(@response.body)

    names = parsed.xpath('//sdo:LearningResource/sdo:name', @ns).map(&:text)
    assert_includes names, 'Training Material Example'

    keywords = parsed.xpath('//sdo:LearningResource/sdo:keywords', @ns).map(&:text)
    assert_includes keywords, 'good'
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
end
