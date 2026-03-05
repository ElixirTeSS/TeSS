require 'test_helper'

class AutocompleteControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  setup do
    AutocompleteSuggestion.add('cat', *%w(meow feline purr paws))
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
    assert_equal [], res['suggestions']

    get :suggestions, params: { field: 'type_that_does_not_have_suggestions', query: 'paw' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal [], res['suggestions']
  end

  test 'should get people suggestions' do
    material = materials(:good_material)
    material.authors.create!(name: 'John Doe', orcid: '0000-0002-1825-0097')
    material.authors.create!(name: 'jane Doe')
    material.authors.create!(name: 'Fred Bloggs')
    materials(:bad_material).authors.create!(name: 'John Doe')
    material2 = materials(:youtube_video_material)
    material2.authors.create!(name: 'John Doe')
    material2.authors.create!(name: 'John Doe', orcid: '0000-0002-1825-0097')
    material2.authors.create!(name: 'John Doe', orcid: '0000-0002-1694-233X')

    sign_in users(:regular_user)

    # Should select distinct name/ORCID pairs
    get :people_suggestions, params: { query: 'jo' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    suggestions = res['suggestions']
    assert_equal 3, suggestions.length, "Should be 3 - 2 with ORCIDs and 1 without. Should not include duplicates."
    assert_equal ['0000-0002-1694-233X', '0000-0002-1825-0097', nil], suggestions.map { |s| s['data']['orcid'] }
    assert_equal ['John Doe', 'John Doe', 'John Doe'], suggestions.map { |s| s['value'] }

    get :people_suggestions, params: { query: 'j' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    suggestions = res['suggestions']
    assert_equal ['jane Doe', 'John Doe', 'John Doe', 'John Doe'], suggestions.map { |s| s['value'] }

    get :people_suggestions, params: { query: 'FRED' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    suggestions = res['suggestions']
    assert_equal ['Fred Bloggs'], suggestions.map { |s| s['value'] }

    get :people_suggestions, params: { query: 'x' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    suggestions = res['suggestions']
    assert_equal [], suggestions
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
