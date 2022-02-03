require 'test_helper'

class ContentProvidersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    mock_images
    @content_provider = content_providers(:goblet)
    #u = users(:regular_user)
    #@content_provider.user_id = u.id
    #@content_provider.save!
    @updated_content_provider = {
      title: 'New title',
      description: 'New description',
      contact: 'New contact'
    }
  end

  #Tests
  # INDEX, NEW, EDIT, CREATE, SHOW, BREADCRUMBS, TABS, API CHECKS

  #INDEX TESTS
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:content_providers)
  end

  test 'should get index with solr enabled' do
    begin
      TeSS::Config.solr_enabled = true

      ContentProvider.stub(:search_and_filter, MockSearch.new(ContentProvider.all)) do
        get :index, params: { q: 'gossip', keywords: 'celebs' }
        assert_response :success
        assert_not_empty assigns(:content_providers)
      end

    ensure
      TeSS::Config.solr_enabled = false
    end
  end

  test 'should get index as json' do
    get :index, params: { format: :json }
    assert_response :success
    assert_not_nil assigns(:content_providers)
  end

  test 'should get index as json-api' do
    get :index, params: { format: :json_api }
    assert_response :success
    assert_not_nil assigns(:content_providers)
    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert body['data'].any?
    assert body['meta']['results-count'] > 0
    assert body['meta'].key?('query')
    assert body['meta'].key?('facets')
    assert body['meta'].key?('available-facets')
    assert_equal content_providers_path, body['links']['self']
  end

  #NEW TESTS
  test 'should get new' do
    sign_in users(:regular_user)
    get :new
    assert_response :success
  end

  test 'should get new page for logged in users only' do
    #Redirect to login if not logged in
    get :new
    assert_response :redirect
    sign_in users(:regular_user)
    #Success for everyone else
    get :new
    assert_response :success
    sign_in users(:admin)
    get :new
    assert_response :success
  end

  test 'should not get new page for basic users' do
    sign_in users(:basic_user)
    get :new
    assert_response :forbidden
  end

  #EDIT TESTS
  test 'should not get edit page for not logged in users' do
    #Not logged in = Redirect to login
    get :edit, params: { id: @content_provider }
    assert_redirected_to new_user_session_path
  end

  #logged in but insufficient permissions = ERROR
  test 'should get edit for content provider owner' do
    sign_in @content_provider.user
    get :edit, params: { id: @content_provider }
    assert_response :success
  end

  test 'should get edit for admin' do
    #Owner of content_provider logged in = SUCCESS
    sign_in users(:admin)
    get :edit, params: { id: @content_provider }
    assert_response :success
  end

  test 'should get edit for curator' do
    sign_in users(:curator)
    get :edit, params: { id: @content_provider }
    assert_response :success
  end

  test 'should not get edit page for non-owner user' do
    sign_in users(:another_regular_user)
    get :edit, params: { id: @content_provider }
    assert :forbidden
  end

  #CREATE TEST
  test 'should create content provider for user' do
    sign_in users(:regular_user)
    assert_difference('ContentProvider.count') do
      post :create, params: { content_provider: {
        title: @content_provider.title,
        url: @content_provider.url,
        image_url: @content_provider.image_url,
        description: @content_provider.description } }
    end
    assert_redirected_to content_provider_path(assigns(:content_provider))
  end

  test 'should create content provider for admin' do
    sign_in users(:admin)
    assert_difference('ContentProvider.count') do
      post :create, params: { content_provider: {
        title: @content_provider.title,
        url: @content_provider.url,
        image_url: @content_provider.image_url,
        description: @content_provider.description } }
    end
    assert_redirected_to content_provider_path(assigns(:content_provider))
  end

  test 'should not create content provider for non-logged in user' do
    assert_no_difference('ContentProvider.count') do
      post :create, params: { content_provider: {
        title: @content_provider.title,
        url: @content_provider.url,
        image_url: @content_provider.image_url,
        description: @content_provider.description } }
    end
    assert_redirected_to new_user_session_path
  end

  #SHOW TEST
  test 'should show content provider' do
    get :show, params: { id: @content_provider }
    assert_response :success
    assert assigns(:content_provider)
  end

  test 'should show content provider as json' do
    get :show, params: { id: @content_provider, format: :json }
    assert_response :success
    assert assigns(:content_provider)
  end

  test 'should show content provider as json-api' do
    get :show, params: { id: @content_provider, format: :json_api }
    assert_response :success
    assert assigns(:content_provider)

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert_equal @content_provider.title, body['data']['attributes']['title']
    assert_equal content_provider_path(assigns(:content_provider)), body['data']['links']['self']
  end

  #UPDATE TEST
  test 'should update content provider' do
    sign_in @content_provider.user
    patch :update, params: { id: @content_provider, content_provider: @updated_content_provider }
    assert_redirected_to content_provider_path(assigns(:content_provider))
  end

  test 'should update content provider if curator' do
    sign_in users(:curator)
    assert_not_equal @content_provider.user, users(:curator)
    patch :update, params: { id: @content_provider, content_provider: @updated_content_provider }
    assert_redirected_to content_provider_path(assigns(:content_provider))
  end

  test 'should not update content provider if not owner or curator etc.' do
    sign_in users(:collaborative_user)
    assert_not_equal @content_provider.user, users(:collaborative_user)
    patch :update, params: { id: @content_provider, content_provider: @updated_content_provider }
    assert_response :forbidden
  end

  #DESTROY TEST
  test 'should destroy content provider owned by user' do
    sign_in @content_provider.user
    assert_difference('ContentProvider.count', -1) do
      delete :destroy, params: { id: @content_provider }
    end
    assert_redirected_to content_providers_path
  end

  test 'should destroy content provider when administrator' do
    sign_in users(:admin)
    assert_difference('ContentProvider.count', -1) do
      delete :destroy, params: { id: @content_provider }
    end
    assert_redirected_to content_providers_path
  end

  test 'should destroy content provider when curator' do
    sign_in users(:curator)
    assert_difference('ContentProvider.count', -1) do
      delete :destroy, params: { id: @content_provider }
    end
    assert_redirected_to content_providers_path
  end

  test 'should not destroy content provider not owned by user' do
    sign_in users(:another_regular_user)
    assert_no_difference('ContentProvider.count') do
      delete :destroy, params: { id: @content_provider }
    end
    assert_response :forbidden
  end

  #CONTENT TESTS
  #BREADCRUMBS
  test 'breadcrumbs for content_providers index' do
    get :index
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li[class=active]', :text => /Content providers/, :count => 1
    end
  end

  test 'breadcrumbs for showing content_provider' do
    get :show, params: { id: @content_provider }
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Content providers/, :count => 1 do
        assert_select 'a[href=?]', content_providers_url, :count => 1
      end
      assert_select 'li[class=active]', :text => /#{@content_provider.title}/, :count => 1
    end
  end

  test 'breadcrumbs for editing content_provider' do
    sign_in users(:admin)
    get :edit, params: { id: @content_provider }
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Content providers/, :count => 1 do
        assert_select 'a[href=?]', content_providers_url, :count => 1
      end
      assert_select 'li', :text => /#{@content_provider.title}/, :count => 1 do
        assert_select 'a[href=?]', content_provider_url(@content_provider), :count => 1
      end
      assert_select 'li[class=active]', :text => /Edit/, :count => 1
    end
  end

  test 'breadcrumbs for creating new content_provider' do
    sign_in users(:regular_user)
    get :new
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Content providers/, :count => 1 do
        assert_select 'a[href=?]', content_providers_url, :count => 1
      end
      assert_select 'li[class=active]', :text => /New/, :count => 1
    end
  end

  #OTHER CONTENT
  test 'content provider has correct tabs' do
    get :show, params: { id: @content_provider }
    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li' do
        assert_select 'a[data-toggle="tab"]', :count => 2 # Materials, Events
      end
      assert_select 'li.disabled', :count => 1 # Activity
    end
  end

  test 'content provider has correct layout' do
    get :show, params: { id: @content_provider }
    assert_response :success
    # assert_select 'h4.nav-heading', :text => /Content provider/
    assert_select 'a[href=?]', @content_provider.url, :count => 2 do
      assert_select 'img[src=?]', ActionController::Base.helpers.asset_path(@content_provider.image.url), :count => 1
    end
    assert_select 'a.btn-info[href=?]', content_providers_path, :count => 1 #Back button
    #Should not show when not logged in
    assert_select 'a.btn-primary[href=?]', edit_content_provider_path(@content_provider), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', content_provider_path(@content_provider), :count => 0 #No Edit
  end

  test 'do not show action buttons when not owner or admin' do
    sign_in users(:another_regular_user)
    get :show, params: { id: @content_provider }
    assert_select 'a.btn-primary[href=?]', edit_content_provider_path(@content_provider), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', content_provider_path(@content_provider), :count => 0 #No Edit
  end

  test 'show action buttons when owner' do
    sign_in @content_provider.user
    get :show, params: { id: @content_provider }
    assert_select 'a.btn-primary[href=?]', edit_content_provider_path(@content_provider), :count => 1
    assert_select 'a.btn-danger[href=?]', content_provider_path(@content_provider), :text => 'Delete', :count => 1
  end

  test 'show action buttons when admin' do
    sign_in users(:admin)
    get :show, params: { id: @content_provider }
    assert_select 'a.btn-primary[href=?]', edit_content_provider_path(@content_provider), :count => 1
    assert_select 'a.btn-danger[href=?]', content_provider_path(@content_provider), :text => 'Delete', :count => 1
  end

  #API Actions
  test 'should find existing content_provider by url' do
    post :check_exists, params: { :format => :json, :content_provider => { :url => @content_provider.url } }
    assert_response :success
    assert_equal(JSON.parse(response.body)['id'], @content_provider.id)
  end

  test 'should find existing content_provider by title' do
    post :check_exists, params: { :format => :json, :content_provider => { :title => @content_provider.title } }
    assert_response :success
    assert_equal(JSON.parse(response.body)['id'], @content_provider.id)
  end

  test 'should return nothing when content_provider does not exist' do
    post :check_exists, params: { :format => :json, :content_provider => { :url => 'http://no-such-site.com' } }
    assert_response :success
    assert_equal '{}', response.body
  end

  test 'should render properly when url parameter missing' do
    post :check_exists, params: { :format => :json, :content_provider => { :url => nil } }
    assert_response :success
    assert_equal '{}', response.body
  end

  test 'can assign nodes by name' do
    sign_in users(:regular_user)
    assert_difference('ContentProvider.count') do
      post :create, params: { content_provider: { title: @content_provider.title, url: @content_provider.url, node_name: nodes(:westeros).name } }
    end
    assert_redirected_to content_provider_path(assigns(:content_provider))

    assert_equal nodes(:westeros).id, assigns(:content_provider).node_id
  end

  test "should update content provider's owner if admin" do
    sign_in users(:admin)
    other_user = users(:another_regular_user)

    patch :update, params: { id: @content_provider, content_provider: { user_id: other_user.id, title: 'test' } }
    assert_redirected_to content_provider_path(assigns(:content_provider))

    assert_equal other_user, assigns(:content_provider).user
  end

  test "should not update content provider's owner if not admin" do
    sign_in @content_provider.user
    other_user = users(:another_regular_user)

    patch :update, params: { id: @content_provider, content_provider: { user_id: other_user.id, title: 'test' } }
    assert_redirected_to content_provider_path(assigns(:content_provider))

    assert_not_equal other_user, assigns(:content_provider).user
    assert_equal @content_provider.user, assigns(:content_provider).user
  end

  test 'should not list unverified events on content provider' do
    bad_user = users(:unverified_user)
    bad_material = bad_user.materials.build(title: 'bla', url: 'http://example.com/spam', description: '123',
                                            doi: 'https://doi.org/10.1080/exa.2021.011', licence: 'Fair',
                                            keywords: %w{ bad material user }, status: 'active',
                                            contact: 'bad contact',
                                            content_provider: @content_provider)
    assert bad_material.user_requires_approval?
    bad_material.save!

    good_user = users(:regular_user)
    good_material = good_user.materials.build(title: 'h', url: 'http://example.com/good-stuff',
                                              description: '456', licence: 'Fair',
                                              doi: 'https://doi.org/10.1080/exa.2021.011',
                                              keywords: %w{ good material user },
                                              contact: 'good contact',
                                              content_provider: @content_provider,
                                              status: 'development')
    refute good_material.user_requires_approval?
    good_material.save!

    get :show, params: { id: @content_provider }
    assert_response :success
    assert_select '#materials a[href=?]', material_path(good_material), count: 1
    assert_select '#materials a[href=?]', material_path(bad_material), count: 0
  end

  test 'should show identifiers dot org button for content provider' do
    get :show, params: { id: @content_provider }

    assert_response :success
    assert_select '.identifiers-button'
    assert_select '#identifiers-link[value=?]', "http://example.com/identifiers/banana:p#{@content_provider.id}"
  end

  # TODO: SOLR tests will not run on TRAVIS. Explore stratergy for testing solr
=begin
      test 'should display filters on index' do
        get :index
        assert_select 'h4.nav-heading', :text => /Content provider/, :count => 0
        assert_select 'div.list-group-item', :count => ContentProvider.count
      end
      test 'should return matching content_providers' do
        get 'index', :format => :json, :q => 'training'
        assert_response :success
        assert response.body.size > 0
      end

      test 'should return no matching content_providers' do
        get 'index', :format => :json, :q => 'kdfsajfklasdjfljsdfljdsfjncvmn'
        assert_response :success
        assert_equal(response.body,'[]')
        end
=end

end

