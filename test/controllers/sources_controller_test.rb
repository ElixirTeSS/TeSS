require 'test_helper'

class SourcesControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers
  include ActiveJob::TestHelper

  setup do
    mock_ingestions
    @user = users :regular_user
    assert_not_nil @user, "regular user is nil"
    @source = sources :first_source
    @new_url = 'https://new.source.loc/sitemap.xml'
    @source_params = {
      source: {
        url: @new_url,
        content_provider_id: @source.content_provider,
        method: @source.method,
        resource_type: @source.resource_type,
      }
    }
    @update_params = {
      finished_at: Time.now,
      records_read: 99,
      records_written: 96,
      resources_added: 9,
      resources_updated: 87,
      resources_rejected: 3,
      log: "Source processed successfully!"
    }
  end

  # INDEX Tests
  test 'public should not get index' do
    get :index
    assert_response :forbidden
  end

  test 'registered should get index' do
    sign_in users(:regular_user)
    get :index
    assert_response :success
    assert_not_empty assigns(:sources), 'sources is empty'
    assert_equal 8, sources.size, 'sources size not matched'
  end

  test 'registered should get index with solr enabled' do
    begin
      TeSS::Config.solr_enabled = true
      method = 'csv'
      resource_type = 'event'
      mock_search = MockSearch.new(Source.where(method: method,
                                                resource_type: resource_type))
      sign_in users(:regular_user)
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

  # SHOW Tests
  test 'public should not show source' do
    get :show, params: { id: @source }
    assert_response :forbidden
  end

  test 'registered should show source' do
    sign_in users(:regular_user)
    get :show, params: { id: @source } do
      assert_response :success
      assert assigns(:source)
      assert_select "h4", count: 2
      assert_select "h4", { count: 1, text: 'Source Details' }
      assert_select "h4", { count: 1, text: 'Last Run' }
      assert_select "strong", { count: 1, text: 'No results found' }
    end
  end

  # NEW Tests
  test 'public should not get new' do
    get :new
    assert_redirected_to new_user_session_path
  end

  test 'registered should not get new' do
    sign_in users(:regular_user)
    get :new
    assert_response :forbidden
  end

  test 'curator user should get new' do
    sign_in users(:curator)
    get :new
    assert_response :success
  end

  test 'admin should get new' do
    sign_in users(:admin)
    get :new
    assert_response :success
  end

  # EDIT Tests
  test 'public should not get edit' do
    # Not logged in = Redirect to login
    get :edit, params: { id: @source }
    assert_redirected_to new_user_session_path
  end

  test 'registered should not get edit' do
    # Regular User = forbidden
    sign_in users(:regular_user)
    get :edit, params: { id: @source }
    assert_response :forbidden
  end

  test 'admin should get edit' do
    # Owner of material logged in = SUCCESS
    sign_in users(:admin)
    get :edit, params: { id: @source }
    assert_response :success
  end

  test 'curator should get edit' do
    sign_in users(:curator)
    second_source = sources(:second_source)
    get :edit, params: { id: second_source }
    assert_response :success
  end

  # CREATE Tests
  test 'public should not create source' do
    assert_no_difference 'Source.count' do
      post :create, params: @source_params
    end
    assert_redirected_to new_user_session_path
  end

  test 'registered should not create source' do
    sign_in users(:regular_user)
    assert_no_difference 'Source.count' do
      post :create, params: @source_params
    end
    assert_response :forbidden
  end

  test 'admin should create source' do
    sign_in users(:admin)
    assert_difference 'Source.count', 1 do
      post :create, params: @source_params
    end
    assert_redirected_to source_path(assigns(:source))
    @source.reload
  end

  test 'curator should create source' do
    sign_in users(:curator)
    assert_difference 'Source.count', 1 do
      post :create, params: @source_params
    end
    assert_redirected_to source_path(assigns(:source))
    @source.reload
  end

  # UPDATE Tests
  test 'public should not update source' do
    patch :update, params: {id: @source, source: @update_params }
    assert_redirected_to new_user_session_path
  end

  test 'registered should not update source' do
    sign_in users(:regular_user)
    patch :update, params: { id: @source, source: @update_params }
    assert_response :forbidden
  end

  test 'curator should update source' do
    sign_in users(:curator)
    assert_no_difference 'Source.count' do
      patch :update, params: {id: @source, source: @update_params } do
        assert_redirected_to source_path(assigns(:source))
        assert assigns(:source)
      end
    end

    # check updated fields
    updated = assigns :source
    assert_not_nil updated, 'updated not found'
    assert_not_nil updated.finished_at, 'finished at is nil'
    assert_equal 99, updated.records_read, 'records read not matched'
    assert_equal 96, updated.records_written, 'records written not matched'
    assert_equal 9, updated.resources_added
    assert_equal 87, updated.resources_updated
    assert_equal 3, updated.resources_rejected
  end

  test 'admin should update source' do
    sign_in users(:admin)
    assert_no_difference 'Source.count' do
      patch :update, params: {id: @source, source: @update_params }
    end
    assert_redirected_to source_path(assigns(:source))
    assert assigns(:source)
    updated = assigns :source
    assert_equal @update_params[:log], updated.log
  end

  # DESTROY Tests
  test 'public should not destroy source' do
    assert_no_difference 'Source.count' do
      delete :destroy, params: { id: sources(:third_source) }
    end
    assert_redirected_to new_user_session_path
  end

  test 'registered should not destroy source' do
    sign_in users(:regular_user)
    assert_no_difference 'Source.count' do
      delete :destroy, params: { id: sources(:third_source) } do
        assert_response :forbidden
      end
    end
  end

  test 'curator should destroy source' do
    sign_in users(:curator)
    assert_difference 'Source.count', -1 do
      delete :destroy, params: { id: sources(:fourth_source) } do
        assert_response :success
        assert_select '@alert-success',
                      { count: 1, text: 'Source was successfully deleted.' }
      end
    end
  end

  test 'admin should destroy source' do
    sign_in users(:admin)
    assert_difference 'Source.count', -2 do
      post :destroy, params: { id: sources(:first_source) } do
        assert_response :success
        assert_select '@alert-success',
                      { count: 1, text: 'Source was successfully deleted.' }
      end
      delete :destroy, params: { id: sources(:fifth_source) } do
        assert_response :success
        assert_select '@alert-success',
                      { count: 1, text: 'Source was successfully deleted.' }
      end
    end
  end

end