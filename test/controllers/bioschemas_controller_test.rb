require 'test_helper'

class BioschemasControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get bioschemas test page' do
    sign_in users(:regular_user)

    get :test

    assert_response :success
  end

  test 'should not get bioschemas test page if anonymous' do
    get :test

    assert_redirected_to new_user_session_path
  end

  test 'should not get bioschemas test page if feature disabled' do
    sign_in users(:regular_user)

    with_settings(feature: { bioschemas_testing: false }) do
      assert_raises(ActionController::RoutingError) do
        get :test
      end
    end
  end

  test 'should test JSON-LD snippet' do
    sign_in users(:regular_user)

    post :run_test, params: { snippet: fixture_file('ext_res.json').read }

    assert_response :success

    output = assigns(:output)
    assert_equal 1, output[:totals]['LearningResources']
    assert_equal 1, output[:resources][:materials].count
    assert_equal "Introduction to 'Metagenomics'", output[:resources][:materials].first[:title]
  end

  test 'should test HTML snippet' do
    sign_in users(:regular_user)

    post :run_test, params: { snippet: fixture_file('gtn/slides-introduction-modified.html').read }

    assert_response :success

    output = assigns(:output)
    assert_equal 1, output[:totals]['LearningResources']
    assert_equal 1, output[:resources][:materials].count
    assert_equal "Introduction to 'Introduction to Galaxy Analyses'", output[:resources][:materials].first[:title]
  end

  test 'should test JSON-LD URL' do
    WebMock.stub_request(:get, 'https://website.com/material.json').
      to_return(status: 200, headers: { content_type: 'application/json' }, body: fixture_file('ext_res.json').read)

    sign_in users(:regular_user)

    post :run_test, params: { url: 'https://website.com/material.json' }

    output = assigns(:output)
    assert_equal 1, output[:totals]['LearningResources']
    assert_equal 1, output[:resources][:materials].count
    assert_equal "Introduction to 'Metagenomics'", output[:resources][:materials].first[:title]
  end

  test 'should test HTML URL' do
    WebMock.stub_request(:get, 'https://website.com/material.html').
      to_return(status: 200, headers: {}, body: fixture_file('gtn/slides-introduction-modified.html').read)

    sign_in users(:regular_user)

    post :run_test, params: { url: 'https://website.com/material.html' }

    assert_response :success

    output = assigns(:output)
    assert_equal 1, output[:totals]['LearningResources']
    assert_equal 1, output[:resources][:materials].count
    assert_equal "Introduction to 'Introduction to Galaxy Analyses'", output[:resources][:materials].first[:title]
  end

  test 'should gracefully handle malformed JSON-LD snippet' do
    # Silence error stdout from RDF library
    old_method = JSON::LD::Reader.instance_method(:logger_common)
    JSON::LD::Reader.define_method(:logger_common) { |*args| }

    sign_in users(:regular_user)

    post :run_test, params: { snippet: "{ 'oh dear }" }

    assert_response :success
    assert_select '.source-log', text:
      'A parsing error occurred while reading the source. Please check your page contains valid JSON-LD or HTML.'
  ensure
    JSON::LD::Reader.define_method(old_method.name, old_method)
  end

  test 'should gracefully handle malformed JSON-LD URL' do
    # Silence error stdout from RDF library
    old_method = JSON::LD::Reader.instance_method(:logger_common)
    JSON::LD::Reader.define_method(:logger_common) { |*args| }

    WebMock.stub_request(:get, 'https://website.com/material.json').
      to_return(status: 200, body: '{ { "wut ;}',
                headers: { content_type: 'application/json' })

    sign_in users(:regular_user)

    post :run_test, params: { url: 'https://website.com/material.json' }

    assert_response :success
    assert_select '.source-log', text:
      'A parsing error occurred while reading: https://website.com/material.json . Please check your page contains valid JSON-LD or HTML.'
  ensure
    JSON::LD::Reader.define_method(old_method.name, old_method)
  end

  test 'should gracefully handle URL timeout' do
    WebMock.stub_request(:get, 'https://website.com/material.html').to_timeout
    sign_in users(:regular_user)

    post :run_test, params: { url: 'https://website.com/material.html' }

    assert_response :unprocessable_entity
    assert flash[:error].include?('Could not access')
  end

  test 'should gracefully handle inaccessible URL' do
    WebMock.stub_request(:get, 'https://website.com/material.html').to_return(status: 404)
    sign_in users(:regular_user)

    post :run_test, params: { url: 'https://website.com/material.html' }

    assert_response :unprocessable_entity
    assert flash[:error].include?('Could not access')
  end

  test 'should gracefully handle missing params' do
    sign_in users(:regular_user)

    post :run_test, params: { }

    assert_response :unprocessable_entity
    assert flash[:error].include?('Please enter a URL')
  end

  test 'should gracefully handle bad URL' do
    sign_in users(:regular_user)

    post :run_test, params: { url: '123' }

    assert_response :unprocessable_entity
    assert flash[:error].include?('Invalid URL')
  end

  test 'should not test for anonymous users' do
    post :run_test, params: { snippet: fixture_file('ext_res.json').read }

    assert_redirected_to new_user_session_path
  end

  test 'should detect resources in JSON-LD snippet with relative IDs' do
    sign_in users(:regular_user)

    post :run_test, params: { snippet: fixture_file('ols_relative_id.json').read }

    assert_response :success

    output = assigns(:output)
    assert_equal 1, output[:totals]['LearningResources']
    assert_equal 1, output[:resources][:materials].count
    assert_equal "https://test.url", output[:resources][:materials].first[:url]
  end

  private

  def fixture_file(filename)
    Rails.root.join('test', 'fixtures', 'files', 'ingestion', filename)
  end
end
