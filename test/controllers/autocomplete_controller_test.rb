# frozen_string_literal: true

require 'test_helper'

class AutocompleteControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    AutocompleteSuggestion.add('cat', *%w[meow feline purr paws])
  end

  test 'should get suggestions' do
    sign_in users(:regular_user)

    get :suggestions, params: { field: 'cat', query: 'p' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal ['paws', 'purr'], res['suggestions']

    get :suggestions, params: { field: 'cat', query: 'paw' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal ['paws'], res['suggestions']

    get :suggestions, params: { field: 'cat', query: 'x' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_empty res['suggestions']

    get :suggestions, params: { field: 'type_that_does_not_have_suggestions', query: 'paw' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_empty res['suggestions']
  end

  test 'should get people suggestions' do
    AutocompleteSuggestion.add('contributors', 'andrew anderson', 'zane zebra')
    AutocompleteSuggestion.add('authors', 'adam eve', 'ruby gems')

    sign_in users(:regular_user)

    get :people_suggestions, params: { query: 'a' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal ['adam eve', 'andrew anderson'], res['suggestions']

    get :people_suggestions, params: { query: 'A' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal ['adam eve', 'andrew anderson'], res['suggestions']

    get :people_suggestions, params: { query: 'ad' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal ['adam eve'], res['suggestions']

    get :people_suggestions, params: { query: '' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal ['adam eve', 'andrew anderson', 'ruby gems', 'zane zebra'], res['suggestions']

    get :people_suggestions, params: { query: 'zane z' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal ['zane zebra'], res['suggestions']

    get :people_suggestions, params: { query: 'q' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_empty res['suggestions']

    get :people_suggestions, params: { field: 'cat', query: 'm' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_empty res['suggestions']
  end

  test 'should not get suggestions if not logged in' do
    get :suggestions, params: { field: 'cat', query: 'p' }, format: :json

    assert_response :unauthorized
  end

  test 'should not get people suggestions if not logged in' do
    get :people_suggestions, params: { query: 'a' }, format: :json

    assert_response :unauthorized
  end
end
