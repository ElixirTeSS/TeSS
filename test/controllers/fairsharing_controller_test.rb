# frozen_string_literal: true

require 'test_helper'

class FairsharingControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'can search' do
    sign_in users(:regular_user)

    VCR.use_cassette('fairsharing/get_token') do
      VCR.use_cassette('fairsharing/search_any_page_1') do
        get :search, params: { query: 'test', format: :json }
      end
    end

    assert_response :success

    res = JSON.parse(response.body)
    results = res['results']

    assert_equal 25, results.length
    assert_equal 'FAIRsharing record for: Clusters of Orthologous Groups (COG) Analysis Ontology',
                 results.last['attributes']['name']
    assert_equal 2, res['next_page']
    assert_nil res['prev_page']
  end

  test 'can get specified page' do
    sign_in users(:regular_user)

    VCR.use_cassette('fairsharing/get_token') do
      VCR.use_cassette('fairsharing/search_any_page_2') do
        get :search, params: { query: 'test', page: 2, format: :json }
      end
    end

    assert_response :success

    res = JSON.parse(response.body)
    results = res['results']

    assert_equal 25, results.length
    assert_equal 'FAIRsharing record for: Logical Observation Identifier Names and Codes',
                 results.last['attributes']['name']
    assert_equal 3, res['next_page']
    assert_equal 1, res['prev_page']
  end

  test 'can search with type filter' do
    sign_in users(:regular_user)

    VCR.use_cassette('fairsharing/get_token') do
      VCR.use_cassette('fairsharing/search_database_fairdom') do
        get :search, params: { query: 'fairdom', page: 1, type: 'database', format: :json }
      end
    end

    assert_response :success

    res = JSON.parse(response.body)
    results = res['results']
    fairdomhub = results[0]

    assert_equal 'FAIRDOMHub', fairdomhub['attributes']['metadata']['name']
    assert_equal 'Database', fairdomhub['attributes']['fairsharing_registry']
    assert_not_equal 'FAIRDOM Community Standards', results[1]['attributes']['metadata']['name']
  end

  test 'anonymous user cannot search' do
    VCR.use_cassette('fairsharing/get_token') do
      VCR.use_cassette('fairsharing/search_any_page_1') do
        get :search, params: { query: 'test', format: :json }
      end
    end

    assert_response :unauthorized
  end
end
