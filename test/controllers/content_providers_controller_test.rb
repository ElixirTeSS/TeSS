require 'test_helper'

class ContentProvidersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    mock_images
    @content_provider = content_providers(:goblet)
    #u = users(:regular_user)
    #@content_provider.user_id = u.id
    #@content_provider.save!
    @updated_content_provider = {
        title: 'New title',
        short_description: 'New description'
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

  #EDIT TESTS
  test 'should not get edit page for not logged in users' do
    #Not logged in = Redirect to login
    get :edit, id: @content_provider
    assert_redirected_to new_user_session_path
  end

    #logged in but insufficient permissions = ERROR
  test 'should get edit for content provider owner' do
    sign_in @content_provider.user
    get :edit, id: @content_provider
    assert_response :success
  end

  test 'should get edit for admin' do
    #Owner of content_provider logged in = SUCCESS
    sign_in users(:admin)
    get :edit, id: @content_provider
    assert_response :success
  end

  test 'should not get edit page for non-owner user' do
    #Administrator = SUCCESS
    sign_in users(:another_regular_user)
    get :edit, id: @content_provider
    assert :forbidden
  end

  #CREATE TEST
  test 'should create content provider for user' do
    sign_in users(:regular_user)
    assert_difference('ContentProvider.count') do
      post :create, content_provider: {description: @content_provider.description, image_url: @content_provider.image_url, title: @content_provider.title, url: @content_provider.url }
    end
    assert_redirected_to content_provider_path(assigns(:content_provider))
  end

  test 'should create content provider for admin' do
    sign_in users(:admin)
    assert_difference('ContentProvider.count') do
      post :create, content_provider: { title: @content_provider.title, url: @content_provider.url, image_url: @content_provider.image_url, description: @content_provider.description }
    end
    assert_redirected_to content_provider_path(assigns(:content_provider))
  end

  test 'should not create content provider for non-logged in user' do
    assert_no_difference('ContentProvider.count') do
      post :create, content_provider: { title: @content_provider.title, url: @content_provider.url, image_url: @content_provider.image_url, description: @content_provider.description }
    end
    assert_redirected_to new_user_session_path
  end

  #SHOW TEST
  test 'should show content provider' do
    get :show, id: @content_provider
    assert_response :success
    assert assigns(:content_provider)
  end


  #UPDATE TEST
  test 'should update content provider' do
    sign_in @content_provider.user
    # patch :update, id: @content_provider, content_provider: { doi: @content_provider.doi,  remote_created_date: @content_provider.remote_created_date,  remote_updated_date: @content_provider.remote_updated_date, short_description: @content_provider.short_description, title: @content_provider.title, url: @content_provider.url }
    patch :update, id: @content_provider, content_provider: @updated_content_provider
    assert_redirected_to content_provider_path(assigns(:content_provider))
  end

  #DESTROY TEST
  test 'should destroy content provider owned by user' do
    sign_in @content_provider.user
    assert_difference('ContentProvider.count', -1) do
      delete :destroy, id: @content_provider
    end
    assert_redirected_to content_providers_path
  end

  test 'should destroy content provider when administrator' do
    sign_in users(:admin)
    assert_difference('ContentProvider.count', -1) do
      delete :destroy, id: @content_provider
    end
    assert_redirected_to content_providers_path
  end

  test 'should not destroy content provider not owned by user' do
    sign_in users(:another_regular_user)
    assert_no_difference('ContentProvider.count') do
      delete :destroy, id: @content_provider
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
    get :show, :id => @content_provider
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
    get :edit, id: @content_provider
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
    get :show, :id => @content_provider
    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li' do
        assert_select 'a[data-toggle="tab"]', :count => 2 # Materials, Events
      end
      assert_select 'li.disabled', :count => 1 # Activity
    end
  end

  test 'content provider has correct layout' do
    get :show, :id => @content_provider
    assert_response :success
    # assert_select 'h4.nav-heading', :text => /Content provider/
    assert_select 'a[href=?]', @content_provider.url, :count => 2 do
      assert_select 'img[src=?]', @content_provider.image.url, :count => 1
    end
    assert_select 'a.btn-info[href=?]', content_providers_path, :count => 1 #Back button
    #Should not show when not logged in
    assert_select 'a.btn-primary[href=?]', edit_content_provider_path(@content_provider), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', content_provider_path(@content_provider), :count => 0 #No Edit
  end

  test 'do not show action buttons when not owner or admin' do
    sign_in users(:another_regular_user)
    get :show, :id => @content_provider
    assert_select 'a.btn-primary[href=?]', edit_content_provider_path(@content_provider), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', content_provider_path(@content_provider), :count => 0 #No Edit
  end

  test 'show action buttons when owner' do
    sign_in @content_provider.user
    get :show, :id => @content_provider
    assert_select 'a.btn-primary[href=?]', edit_content_provider_path(@content_provider), :count => 1
    assert_select 'a.btn-danger[href=?]', content_provider_path(@content_provider), :text => 'Delete', :count => 1
  end

  test 'show action buttons when admin' do
    sign_in users(:admin)
    get :show, :id => @content_provider
    assert_select 'a.btn-primary[href=?]', edit_content_provider_path(@content_provider), :count => 1
    assert_select 'a.btn-danger[href=?]', content_provider_path(@content_provider), :text => 'Delete', :count => 1
  end

  #API Actions
  test 'should find existing content_provider by title' do
    post 'check_exists', :format => :json,  :title => @content_provider.title
    assert_response :success
    assert_equal(JSON.parse(response.body)['title'], @content_provider.title)
  end

  test 'should find existing content_provider by url' do
    post 'check_exists', :format => :json,  :url => @content_provider.url
    assert_response :success
    assert_equal(JSON.parse(response.body)['title'], @content_provider.title)
  end

  test 'should return nothing when content_provider does not exist' do
    post 'check_exists', :format => :json,  :title => 'This title should not exist'
    assert_response :success
    assert_equal(response.body, '')
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

  test "should find content_provider by title" do
    post 'check_exists', :format => :json,  :title => @content_provider.title
    assert_response :success
    assert_equal(JSON.parse(response.body)['title'], @content_provider.title)
  end
  test "should return nothing when content_provider does't exist" do
    post 'check_exists', :format => :json,  :title => 'This title should not exist'
    assert_response :success
    assert_equal(response.body, "")
  end

end

