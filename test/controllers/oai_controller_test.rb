require 'test_helper'

class OaiControllerTest < ActionDispatch::IntegrationTest
  setup do
    @material = materials(:good_material)
    @user = users(:regular_user)
    @material.user_id = @user.id
    @material.save!
  end

  test 'should get endpoint' do
    get '/oai-pmh'
    assert_response :success
    assert_includes @response.body, 'xml-stylesheet'
  end

  test 'OAI Identify verb returns expected repository info' do
    get '/oai-pmh', params: { verb: 'Identify' }

    assert_response :success

    assert_includes @response.body, '<protocolVersion>2.0</protocolVersion>'
  end

  test 'OAI ListMetadataFormates verb returns expected repository info' do
    get '/oai-pmh', params: { verb: 'ListMetadataFormats' }

    assert_response :success

    assert_includes @response.body, 'oai_dc'
    assert_includes @response.body, 'rdf'
  end

  test 'OAI ListRecords returns material in oai_dc format' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'oai_dc' }

    assert_response :success
    body = @response.body

    assert_includes body, @material.title
    @material.keywords.each { |keyword| assert_includes body, keyword }
    assert_includes body, @material.doi
  end

  test 'OAI ListRecords returns material in rdf format' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'rdf' }

    assert_response :success
    body = @response.body

    assert_includes body, '<sdo:name>Training Material Example</sdo:name>'
    assert_includes body, '<sdo:keywords>good</sdo:keywords>'
  end

  test 'OAI ListRecords returns only visible materials' do
    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'rdf' }
    assert_response :success
    assert_includes @response.body, '<sdo:name>Training Material Example</sdo:name>'

    @material.visible = false
    @material.save!

    get '/oai-pmh', params: { verb: 'ListRecords', metadataPrefix: 'oai_dc' }
    assert_response :success
    assert_not_includes @response.body, '<sdo:name>Training Material Example</sdo:name>'
  end
end
