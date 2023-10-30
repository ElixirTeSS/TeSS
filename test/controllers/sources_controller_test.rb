require 'test_helper'

class SourcesControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

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

    @test_results = { events: [], materials: [], messages: [], run_time: 120, finished_at: Time.now }
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
    with_settings(solr_enabled: true) do
      method = 'event_csv'
      mock_search = MockSearch.new(Source.where(method: method))
      sign_in users(:admin)
      Source.stub(:search_and_filter, mock_search) do
        get :index, params: { method: method }
        assert_response :success
        assert_not_empty assigns(:sources)
        assert_equal 2, assigns(:sources).size, 'provider'
      end
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
    assert_select 'div.alert.alert-info', text: /This source will need to be approved/
  end

  test 'user should not get new if user creation feature disabled' do
    with_settings(feature: { user_source_creation: false }) do
      sign_in users(:regular_user)
      get :new, params: { content_provider_id: content_providers(:goblet) }
      assert_response :forbidden
    end
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
    assert_select 'div.alert.alert-info', text: /This source will need to be approved/, count: 0
  end

  test 'user should only see enabled method options' do
    with_settings(user_ingestion_methods: ['bioschemas']) do
      sign_in users(:regular_user)
      get :new, params: { content_provider_id: content_providers(:goblet) }
      assert_response :success
      assert_select '#source_method option[value=?]', 'tess_event', { count: 0 },
                    "Should not show ingestion methods unavailable to user"
      assert_select '#source_method option[value=?]', 'bioschemas', { count: 1 },
                    "Should show ingestion methods available to user"
    end
  end

  test 'admin should see all method options' do
    with_settings(user_ingestion_methods: ['bioschemas']) do
      sign_in users(:admin)
      get :new, params: { content_provider_id: content_providers(:goblet) }
      assert_response :success
      assert_select '#source_method option[value=?]', 'tess_event', { count: 1 },
                    "Should show all ingestion methods"
      assert_select '#source_method option[value=?]', 'bioschemas', { count: 1 },
                    "Should show all ingestion methods"
    end
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

  test 'user should get edit for approved source' do
    source = sources(:first_source)
    user = source.user
    sign_in user
    assert source.approved?
    get :edit, params: { id: source }
    assert_response :success
    assert_select 'div.alert.alert-warning', text: /If the source URL or ingestion method/
  end

  test 'user should not get edit for source with approval requested' do
    source = sources(:approval_requested_source)
    user = source.user
    sign_in user
    get :edit, params: { id: source }
    assert_response :forbidden
  end

  test 'user should get edit for unapproved source' do
    source = sources(:unapproved_source)
    user = source.user
    sign_in user
    get :edit, params: { id: source }
    assert_response :success
    assert_select 'div.alert.alert-warning', text: /If the source URL or ingestion method/, count: 0
  end

  test 'admin should get edit' do
    # Owner of material logged in = SUCCESS
    sign_in users(:admin)
    assert @source.approved?
    get :edit, params: { id: @source }
    assert_response :success
    assert_select 'div.alert.alert-warning', text: /If the source URL or ingestion method/, count: 0
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
    refute_permitted SourcePolicy, user, :create?, Source
    assert_no_difference 'Source.count' do
      post :create, params: @source_params
    end
    assert_response :forbidden
  end

  test 'user can create source for their content provider' do
    sign_in @user
    assert_permitted SourcePolicy, @user, :create?, Source
    assert_difference 'Source.count', 1 do
      post :create, params: @source_params
    end
    assert_redirected_to source_path(assigns(:source))
  end

  test 'user cannot create source if user creation feature disabled' do
    with_settings(feature: { user_source_creation: false }) do
      sign_in @user
      assert_no_difference 'Source.count' do
        post :create, params: @source_params
      end
      assert_response :forbidden
    end
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

  test 'user should update content provider-owned source, but approval status is reset' do
    sign_in @user
    assert @source.approved?
    patch :update, params: { id: @source, source: @update_params }
    updated = assigns(:source)
    assert updated
    assert updated.not_approved?
    assert_equal 'bioschemas', updated.method
  end

  test 'user cannot update source with approval requested' do
    source = sources(:approval_requested_source)
    user = source.user
    sign_in user
    assert source.approval_requested?
    patch :update, params: { id: source, source: @update_params }
    assert source.reload.approval_requested?
    assert_response :forbidden
  end

  test 'user can update unapproved source' do
    source = sources(:unapproved_source)
    user = source.user
    sign_in user
    assert source.not_approved?
    patch :update, params: { id: source, source: @update_params }
    updated = assigns(:source)
    assert updated
    assert updated.not_approved?
  end

  test 'user cannot change approval status for source' do
    source = sources(:unapproved_source)
    user = source.user
    sign_in user
    assert source.not_approved?
    patch :update, params: { id: source, source: { approval_status: 'approved' } }
    updated = assigns(:source)
    assert updated
    assert updated.not_approved?
  end

  test 'admin can change approval status for source' do
    source = sources(:unapproved_source)
    sign_in users(:admin)
    assert source.not_approved?
    patch :update, params: { id: source, source: { approval_status: 'approved' } }
    updated = assigns(:source)
    assert updated
    assert updated.approved?
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

  test 'user can destroy approved, content provider-owned source' do
    sign_in @user
    assert @source.approved?
    assert_difference 'Source.count', -1 do
      delete :destroy, params: { id: @source }
      assert_redirected_to content_provider_path(@source.content_provider)
      assert_equal 'Source was successfully deleted.', flash[:notice]
    end
  end

  test 'user cannot destroy source with approval requested' do
    source = sources(:approval_requested_source)
    user = source.user
    sign_in user
    assert source.approval_requested?
    assert_no_difference 'Source.count' do
      delete :destroy, params: { id: source }
      assert_response :forbidden
    end
  end

  test 'user can destroy unapproved source' do
    source = sources(:unapproved_source)
    user = source.user
    sign_in user
    assert source.not_approved?
    assert_difference 'Source.count', -1 do
      delete :destroy, params: { id: source }
      assert_redirected_to content_provider_path(source.content_provider)
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

  test 'user can run tests' do
    source = sources(:unapproved_source)
    user = source.user
    sign_in user

    post :test, params: { id: source, format: :json }

    assert_response :success
    assert JSON.parse(response.body)['id'].present?
  end

  test 'unaffiliated user cannot run tests' do
    source = sources(:unapproved_source)
    user = users(:another_regular_user)
    sign_in user

    post :test, params: { id: source, format: :json }

    assert_response :forbidden
    assert JSON.parse(response.body)['error'].present?
  end

  test 'user can get test results' do
    source = sources(:unapproved_source)
    user = source.user
    sign_in user
    source.test_results = @test_results
    assert source.test_results

    get :test_results, params: { id: source }, xhr: true

    assert_response :success
    assert_select 'h4', text: 'Last Test Results'
  ensure
    path = source.send(:test_results_path)
    FileUtils.rm(path) if File.exist?(path)
  end

  test 'unaffiliated user cannot get test results' do
    source = sources(:unapproved_source)
    user = users(:another_regular_user)
    sign_in user
    source.test_results = @test_results
    assert source.test_results

    get :test_results, params: { id: source }, xhr: true

    assert_response :forbidden
  ensure
    path = source.send(:test_results_path)
    FileUtils.rm(path) if File.exist?(path)
  end

  test 'user cannot get test results if they do not exist' do
    source = sources(:unapproved_source)
    user = source.user
    sign_in user
    refute source.test_results

    get :test_results, params: { id: source }, xhr: true

    assert_response :not_found
  end

  test 'user can request approval' do
    source = sources(:unapproved_source)
    user = source.user
    sign_in user
    refute source.approval_requested?

    assert_enqueued_email_with(CurationMailer, :source_requires_approval, args: [source, user]) do
      post :request_approval, params: { id: source }

      assert_redirected_to source
    end

    assert source.reload.approval_requested?
  end

  test 'user cannot request approval if already requested' do
    source = sources(:approval_requested_source)
    user = source.user
    sign_in user
    assert source.approval_requested?

    assert_no_enqueued_emails do
      post :request_approval, params: { id: source }

      assert_redirected_to source
      assert_includes flash[:error], 'already'
    end
  end

  test 'user cannot request approval if already approved' do
    source = sources(:first_source)
    user = source.user
    sign_in user
    assert source.approved?

    assert_no_enqueued_emails do
      post :request_approval, params: { id: source }

      assert_redirected_to source
      assert_includes flash[:error], 'approved'
    end
  end

  test 'unaffiliated user cannot request approval' do
    source = sources(:unapproved_source)
    user = users(:another_regular_user)
    sign_in user
    refute source.approval_requested?

    assert_no_enqueued_emails do
      post :request_approval, params: { id: source }

      assert_response :forbidden
    end

    refute source.reload.approval_requested?
  end

  test 'ignores unrecognized fields when displaying test results' do
    source = sources(:unapproved_source)
    user = source.user
    sign_in user
    source.test_results = {
      events: [{ title: 'test 123', url: 'https://tess.elixir-europe.org', some_random_field: 'hello' }],
      materials: [],
      messages: [], run_time: 120, finished_at: Time.now }
    assert source.test_results

    get :test_results, params: { id: source }, xhr: true

    assert_response :success
    assert_select 'h4', text: 'Last Test Results'
    assert_select '#events' do
      assert_select 'h4', text: 'test 123'
      assert_select 'a[href=?]', 'https://tess.elixir-europe.org'
    end
  ensure
    path = source.send(:test_results_path)
    FileUtils.rm(path) if File.exist?(path)
  end
end