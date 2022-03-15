require 'test_helper'

class SourcesControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers
  include ActiveJob::TestHelper

  setup do
    mock_ingestions
    @user = users :regular_user
    assert_not_nil @user, "regular user is nil"
  end

  #INDEX TESTS
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_empty assigns(:sources), 'sources is empty'
    assert_equal 6, sources.size, 'sources size not matched'
  end

  test 'should get index with solr enabled' do
    begin
      TeSS::Config.solr_enabled = true
      method = 'csv'
      resource_type = 'event'
      mock_search =  MockSearch.new(Source.where(method: method,
                                                 resource_type: resource_type) )

      Source.stub(:search_and_filter, mock_search) do
        get :index, params: { method: method, resource_type: resource_type }
        assert_response :success
        assert_not_empty assigns(:sources)
        assert_equal 2, assigns(:sources).size, 'provider'
      end
    ensure
      TeSS::Config.solr_enabled = false
    end
  end

  #NEW TESTS
  test 'regular user should not get new' do
    sign_in users(:regular_user)
    get :new
    assert_response :forbidden
  end

  test 'curator user should get new' do
    sign_in users(:curator)
    get :new
    assert_response :success
  end

  test 'admin user should get new' do
    sign_in users(:admin)
    get :new
    assert_response :success
  end


end