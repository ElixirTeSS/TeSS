require 'test_helper'

class CollectionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    mock_images
    @collection = collections(:one)
    @updated_collection = {
        title: 'New title',
        short_description: 'New description'
    }
  end
  #INDEX TESTS
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:collections)
  end

  test 'should get index as json' do
    get :index, format: :json
    assert_response :success
    assert_not_nil assigns(:collections)
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
    get :edit, params: { id: @collection }
    assert_redirected_to new_user_session_path
  end

    #logged in but insufficient permissions = ERROR
  test 'should get edit for collections owner' do
    sign_in @collection.user
    get :edit, params: { id: @collection }
    assert_response :success
  end

  test 'should get edit for admin' do
    #Owner of collections logged in = SUCCESS
    sign_in users(:admin)
    get :edit, params: { id: @collection }
    assert_response :success
  end

  test 'should not get edit page for non-owner user' do
    #Administrator = SUCCESS
    sign_in users(:another_regular_user)
    get :edit, params: { id: @collection }
    assert :forbidden
  end

  #CREATE TEST
  test 'should create collections for user' do
    sign_in users(:regular_user)
    assert_difference('Collection.count') do
      post :create, params: { collections: { title: @collection.title, image_url: @collection.image_url, description: @collection.description } }
    end
    assert_redirected_to collections_path(assigns(:collections))
  end

  test 'should create collections for admin' do
    sign_in users(:admin)
    assert_difference('Collection.count') do
      post :create, params: { collections: { title: @collection.title, image_url: @collection.image_url, description: @collection.description } }
    end
    assert_redirected_to collections_path(assigns(:collections))
  end

  test 'should not create collections for non-logged in user' do
    assert_no_difference('Collection.count') do
      post :create, params: { collections: { title: @collection.title, image_url: @collection.image_url, description: @collection.description } }
    end
    assert_redirected_to new_user_session_path
  end

  #SHOW TEST
  test 'should show collections' do
    get :show, params: { id: @collection }
    assert_response :success
    assert assigns(:collections)
  end

  test 'should show collections as json' do
    get :show, params: { id: @collection, format: :json }
    assert_response :success
    assert assigns(:collections)
  end

  #UPDATE TEST
  test 'should update collections' do
    sign_in @collection.user
    patch :update, params: { id: @collection, collections: @updated_collection }
    assert_redirected_to collections_path(assigns(:collections))
  end

  #DESTROY TEST
  test 'should destroy collections owned by user' do
    sign_in @collection.user
    assert_difference('Collection.count', -1) do
      delete :destroy, params: { id: @collection }
    end
    assert_redirected_to collectiond_path
  end

  test 'should destroy collections when administrator' do
    sign_in users(:admin)
    assert_difference('Collection.count', -1) do
      delete :destroy, params: { id: @collection }
    end
    assert_redirected_to collectiond_path
  end

  test 'should not destroy collections not owned by user' do
    sign_in users(:another_regular_user)
    assert_no_difference('Collection.count') do
      delete :destroy, params: { id: @collection }
    end
    assert_response :forbidden
  end


  #CONTENT TESTS
  #BREADCRUMBS
  test 'breadcrumbs for collections index' do
    get :index
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li[class=active]', :text => /Collections/, :count => 1
    end
  end

  test 'breadcrumbs for showing collections' do
    get :show, params: { :id => @collection }
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Collections/, :count => 1 do
        assert_select 'a[href=?]', collections_url, :count => 1
      end
      assert_select 'li[class=active]', :text => /#{@collection.title}/, :count => 1
    end
  end

  test 'breadcrumbs for editing collections' do
    sign_in users(:admin)
    get :edit, params: { id: @collection }
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Collections/, :count => 1 do
        assert_select 'a[href=?]', collections_url, :count => 1
      end
      assert_select 'li', :text => /#{@collection.title}/, :count => 1 do
        assert_select 'a[href=?]', collections_url(@collection), :count => 1
      end
      assert_select 'li[class=active]', :text => /Edit/, :count => 1
    end
  end

  test 'breadcrumbs for creating new collections' do
    sign_in users(:regular_user)
    get :new
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Collections/, :count => 1 do
        assert_select 'a[href=?]', collections_url, :count => 1
      end
      assert_select 'li[class=active]', :text => /New/, :count => 1
    end
  end

  #OTHER CONTENT
  test 'collections has correct tabs' do
    get :show, params: { :id => @collection }
    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li.disabled', :count => 3 # This collections has no events, materials or activity
    end

    collections(:with_resources).materials << materials(:good_material)
    collections(:with_resources).events << events(:one)

    get :show, params: { :id => collections(:with_resources) }
    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li' do
        assert_select 'a[data-toggle="tab"]', :count => 3 # Events, Materials, Activity (added the resources)
      end
    end
  end

  test 'collections has correct layout' do
    get :show, params: { :id => @collection }
    assert_response :success
    assert_select 'div.search-results-count', :count => 2 #Has results
    assert_select 'a.btn-info', :text => 'Back', :count => 1 #No Edit
    #Should not show when not logged in
    assert_select 'a.btn-primary[href=?]', edit_collections_path(@collection), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', collections_path(@collection), :count => 0 #No Edit

  end

  test 'do not show action buttons when not owner or admin' do
    sign_in users(:another_regular_user)
    get :show, params: { :id => @collection }
    assert_select 'a.btn-primary[href=?]', edit_collections_path(@collection), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', collections_path(@collection), :count => 0 #No Edit
  end

  test 'show action buttons when owner' do
    sign_in @collection.user
    get :show, params: { :id => @collection }
    assert_select 'a.btn-primary[href=?]', edit_collections_path(@collection), :count => 1
    assert_select 'a.btn-danger[href=?]', collections_path(@collection), :text => 'Delete', :count => 1
  end

  test 'show action buttons when admin' do
    sign_in users(:admin)
    get :show, params: { :id => @collection }
    assert_select 'a.btn-primary[href=?]', edit_collections_path(@collection), :count => 1
    assert_select 'a.btn-danger[href=?]', collections_path(@collection), :text => 'Delete', :count => 1
  end

  #API Actions
  test "should remove materials from collections" do
    sign_in users(:regular_user)
    collections = collections(:with_resources)
    collections.materials = [materials(:biojs), materials(:interpro)]
    collections.save!
    assert_difference('collections.materials.count', -2) do
      patch :update, params: { collections: { material_ids: [''] }, id: collections.id }
    end
  end     
  
  test "should add events to collections" do
    sign_in users(:regular_user)
    assert_difference('@collection.events.count', +2) do
      patch :update, params: { collections: { event_ids: [events(:one), events(:two)]}, id: @collection.id }
    end
  end
  
  test "should remove events from collections" do
    sign_in users(:regular_user)
    collections = collections(:with_resources)
    collections.events = [events(:one), events(:two)]
    collections.save!
    assert_difference('collections.events.count', -2) do
      patch :update, params: { collections: { event_ids: ['']}, id: collections.id }
    end
  end

  test 'should not allow access to private collections' do
    get :show, params: { id: collections(:secret_collections) }
    assert_response :forbidden
  end

  test 'should allow access to private collections if privileged' do
    sign_in users(:regular_user)
    get :show, params: { id: collections(:secret_collections) }
    assert_response :success
  end

  test 'should hide private collections from index' do
    get :index
    assert_response :success
    assert_not_includes assigns(:collections).map(&:id), collections(:secret_collections).id
  end

  test 'should not hide private collections from index from collections owner' do
    sign_in users(:regular_user)
    get :index
    assert_response :success
    assert_includes assigns(:collections).map(&:id), collections(:secret_collections).id
  end

  test 'should not hide private collections from index from admin' do
    sign_in users(:admin)
    get :index
    assert_response :success
    assert_includes assigns(:collections).map(&:id), collections(:secret_collections).id
  end

end
