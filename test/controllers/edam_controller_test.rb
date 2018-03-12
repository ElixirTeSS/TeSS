require 'test_helper'

class EdamControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should filter topics' do
    get :topics, filter: 'metab', format: :json
    assert_response :success

    res = JSON.parse(response.body)
    assert_equal 1, res.length
    assert_includes res.map { |t| t['preferred_label'] }, 'Metabolomics'
  end

  test 'should filter operations' do
    get :operations, filter: 'metab', format: :json
    assert_response :success

    res = JSON.parse(response.body)
    assert_equal 2, res.length
    assert_includes res.map { |t| t['preferred_label'] }, 'Metabolic network modelling'
  end

  test 'should filter all terms' do
    get :terms, filter: 'rna', format: :json
    assert_response :success

    res = JSON.parse(response.body)
    assert_equal 12, res.length
    labels = res.map { |t| t['preferred_label'] }
    uris = res.map { |t| t['uri'] }
    assert_includes labels, 'RNA splicing'
    assert_includes uris, 'http://edamontology.org/topic_3523'
    assert_includes uris, 'http://edamontology.org/operation_3563'
  end

  test 'should filter multiple times' do
    get :terms, filter: 'data', format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal 16, res.length
    assert_includes res.map { |t| t['preferred_label'] }, 'Database management'

    get :terms, filter: 'xylophone', format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal 0, res.length

    get :terms, filter: 'data', format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal 16, res.length
    assert_includes res.map { |t| t['preferred_label'] }, 'Database management'
  end

end
