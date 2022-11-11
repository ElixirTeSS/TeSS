require 'test_helper'

class SourcesControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers
  include ActiveJob::TestHelper

  setup do
    mock_ingestions
    @user = users(:regular_user)
    @source = sources(:first_source)
    @new_url = 'https://new.source.loc/sitemap.xml'

    @source_params = {
      content_provider_id: @source.content_provider,
      source: {
        url: @new_url,
        method: 'event_csv'
      }
    }

    @update_params = {
      method: 'bioschemas'
    }
  end

  # INDEX Tests
  test 'public should not get index' do
    get :index
    assert_response :forbidden
  end

  test 'regular user should not get index' do
    sign_in users(:regular_user)
    get :index
    assert_response :forbidden
  end

  test 'admin should get index' do
    sign_in users(:admin)
    get :index
    assert_response :success
    assert_not_empty assigns(:sources), 'sources is empty'
  end

  test 'admin should get index with solr enabled' do
    begin
      TeSS::Config.solr_enabled = true
      method = 'event_csv'
      mock_search = MockSearch.new(Source.where(method: method))
      sign_in users(:admin)
      Source.stub(:search_and_filter, mock_search) do
        get :index, params: { method: method }
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
    get :new, params: { content_provider_id: content_providers(:goblet) }
    assert_redirected_to new_user_session_path
  end

  test 'user should get new for their content provider' do
    sign_in users(:regular_user)
    get :new, params: { content_provider_id: content_providers(:goblet) }
    assert_response :success
  end

  test 'unaffiliated user should not get new' do
    sign_in users(:another_regular_user)
    get :new, params: { content_provider_id: content_providers(:goblet) }
    assert_response :forbidden
  end


  test 'curator user should get new' do
    sign_in users(:curator)
    get :new, params: { content_provider_id: content_providers(:goblet) }
    assert_response :success
  end

  test 'admin should get new' do
    sign_in users(:admin)
    get :new, params: { content_provider_id: content_providers(:goblet) }
    assert_response :success
  end

  # EDIT Tests
  test 'public should not get edit' do
    # Not logged in = Redirect to login
    get :edit, params: { id: @source }
    assert_redirected_to new_user_session_path
  end

  test 'user should not get edit for unowned source' do
    # Regular User = forbidden
    sign_in users(:another_regular_user)
    get :edit, params: { id: @source }
    assert_response :forbidden
  end

  test 'user should get edit for content provider-owned source' do
    sign_in @user
    get :edit, params: { id: @source }
    assert_response :success
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

  test 'unaffiliated user cannot create source for content provider' do
    user = users(:another_regular_user)
    sign_in user
    refute_permitted SourcePolicy, user, :manage?, @source.content_provider
    assert_no_difference 'Source.count' do
      post :create, params: @source_params
    end
    assert_response :forbidden
  end

  test 'user can create source for their content provider' do
    sign_in @user
    assert_permitted SourcePolicy, @user, :manage?, @source.content_provider
    assert_difference 'Source.count', 1 do
      post :create, params: @source_params
    end
    assert_redirected_to source_path(assigns(:source))
  end

  test 'admin should create source' do
    sign_in users(:admin)
    assert_difference 'Source.count', 1 do
      post :create, params: @source_params
    end
    assert_redirected_to source_path(assigns(:source))
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
    patch :update, params: { id: @source, source: @update_params }
    assert_redirected_to new_user_session_path
  end

  test 'unaffiliated user should not update source' do
    sign_in users(:another_regular_user)
    patch :update, params: { id: @source, source: @update_params }
    assert_response :forbidden
  end

  test 'user should update content provider-owned source' do
    sign_in @user
    patch :update, params: { id: @source, source: @update_params }
    updated = assigns(:source)
    assert updated
    assert_equal 'bioschemas', updated.method
  end

  test 'curator should update source' do
    sign_in users(:curator)
    assert_no_difference 'Source.count' do
      patch :update, params: { id: @source, source: @update_params }
      assert_redirected_to source_path(assigns(:source))
    end
    updated = assigns(:source)
    assert updated
    assert_equal 'bioschemas', updated.method
  end

  test 'admin should update source' do
    sign_in users(:admin)
    assert_no_difference 'Source.count' do
      patch :update, params: { id: @source, source: @update_params }
      assert_redirected_to source_path(assigns(:source))
    end
    updated = assigns(:source)
    assert updated
    assert_equal 'bioschemas', updated.method
  end

  # DESTROY Tests
  test 'public should not destroy source' do
    assert_no_difference 'Source.count' do
      delete :destroy, params: { id: sources(:third_source) }
    end
    assert_redirected_to new_user_session_path
  end

  test 'user should destroy content provider-owned source' do
    sign_in @user
    assert_difference 'Source.count', -1 do
      delete :destroy, params: { id: @source }
      assert_redirected_to content_provider_path(@source.content_provider)
      assert_equal 'Source was successfully deleted.', flash[:notice]
    end
  end

  test 'unaffiliated user should not destroy source' do
    sign_in users(:another_regular_user)
    assert_no_difference 'Source.count' do
      delete :destroy, params: { id: sources(:third_source) }
      assert_response :forbidden
    end
  end

  test 'curator should destroy source' do
    sign_in users(:curator)
    assert_difference 'Source.count', -1 do
      delete :destroy, params: { id: sources(:fourth_source) }
      assert_redirected_to sources_path
      assert_equal 'Source was successfully deleted.', flash[:notice]
    end
  end

  test 'admin should destroy source' do
    sign_in users(:admin)
    assert_difference 'Source.count', -2 do
      post :destroy, params: { id: sources(:first_source) }
      assert_redirected_to sources_path
      assert_equal 'Source was successfully deleted.', flash[:notice]

      delete :destroy, params: { id: sources(:fifth_source) }
      assert_redirected_to sources_path
      assert_equal 'Source was successfully deleted.', flash[:notice]
    end
  end

  test 'admin can view general source index' do
    sign_in users(:admin)
    get :index
    assert_response :success
  end

  test 'regular user cannot view general source index' do
    sign_in users(:regular_user)
    get :index
    assert_response :forbidden
  end

  test 'admin can approve source' do
    sign_in users(:admin)
    source = sources(:unapproved_source)
    refute source.approved?

    patch :update, params: { id: source, source: { approval_status: 'approved' } }

    assert_redirected_to source_path(assigns(:source))
    assert source.reload.approved?
  end

  test 'regular user cannot approve source' do
    sign_in @user
    source = sources(:unapproved_source)
    refute source.approved?

    patch :update, params: { id: source, source: { approval_status: 'approved' } }

    assert_redirected_to source_path(assigns(:source))
    refute source.reload.approved?
  end
end