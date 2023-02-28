require 'test_helper'

class AutocompletersControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  test 'should get suggestions' do
    sign_in users(:regular_user)

    AutocompleteManager.stub(:file_path, Rails.root.join('test', 'fixtures', 'files', 'cat_suggestions.txt')) do
      get :suggestions, params: { field: 'cat', query: 'p' }, format: :json
      assert_response :success
      res = JSON.parse(response.body)
      assert_equal ['purr', 'paws'], res['suggestions']

      get :suggestions, params: { field: 'cat', query: 'paw' }, format: :json
      assert_response :success
      res = JSON.parse(response.body)
      assert_equal ['paws'], res['suggestions']

      get :suggestions, params: { field: 'cat', query: 'x' }, format: :json
      assert_response :success
      res = JSON.parse(response.body)
      assert_equal [], res['suggestions']
    end

    get :suggestions, params: { field: 'type_that_does_not_have_suggestions', query: 'paw' }, format: :json
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal [], res['suggestions']
  end

  test 'should not get suggestions if not logged in' do
    AutocompleteManager.stub(:file_path, Rails.root.join('test', 'fixtures', 'files', 'cat_suggestions.txt')) do
      get :suggestions, params: { field: 'cat', query: 'p' }, format: :json

      assert_response :unauthorized
    end
  end
end
