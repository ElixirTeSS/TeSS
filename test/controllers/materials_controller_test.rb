require 'test_helper'

class MaterialsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  setup do
    @material = materials(:good_material)
    @updated_material = {
        title: 'New title',
        short_description: 'New description',
        url: 'http://new.url.com'
    }
  end

  #Tests
  # INDEX, NEW, EDIT, CREATE, SHOW, BREADCRUMBS, TABS, API CHECKS


  #INDEX TESTS
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:materials)
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
  test 'should get edit page for material owners and admins' do
    #Not logged in = Redirect to login
    get :edit, id: @material
    assert_response :redirect
  end
  test 'should not get edit page for non-owner regular user' do
    #logged in but insufficient permissions = ERROR
    sign_in users(:regular_user)
    get :edit, id: @material
    assert_response :error
  end

  test 'should get edit for owner user' do
    #Owner of material logged in = SUCCESS
    sign_in users(:regular_user)
    u = assigns(:regular_user)
    @material.owner = u
    @material.save!
    get :edit, id: @material
    assert_response :success
  end

  test 'should get edit for administrator user' do
    #Administrator = SUCCESS
    sign_in users(:admin)
    get :edit, id: @material
    assert_response :success
  end

  #CREATE TEST
  test 'should create material for user' do
    sign_in users(:regular_user)
    assert_difference('Material.count') do
      post :create, material: { doi: @material.doi,  remote_created_date: @material.remote_created_date, remote_updated_date: @material.remote_updated_date, short_description: @material.short_description, title: @material.title, url: @material.url }
    end
    assert_redirected_to material_path(assigns(:material))
  end

  test 'should create material for admin' do
    sign_in users(:admin)
    assert_difference('Material.count') do
      post :create, material: { doi: @material.doi,  remote_created_date: @material.remote_created_date, remote_updated_date: @material.remote_updated_date, short_description: @material.short_description, title: @material.title, url: @material.url }
    end
    assert_redirected_to material_path(assigns(:material))
  end

  test 'should not create material for non-logged in user' do
    assert_no_difference('Material.count') do
      post :create, material: { doi: @material.doi,  remote_created_date: @material.remote_created_date, remote_updated_date: @material.remote_updated_date, short_description: @material.short_description, title: @material.title, url: @material.url }
    end
    assert_redirected_to new_user_session_path
  end

  #SHOW TEST
  test 'should show material' do
    get :show, id: @material
    assert_response :success
  end

  test 'should get edit' do
    sign_in users(:regular_user)
    get :edit, id: @material
    assert_response :success
  end

  test '       ' do

  end

  #UPDATE TEST
  test 'should update material' do
    sign_in users(:regular_user)
    # patch :update, id: @material, material: { doi: @material.doi,  remote_created_date: @material.remote_created_date,  remote_updated_date: @material.remote_updated_date, short_description: @material.short_description, title: @material.title, url: @material.url }
    patch :update, id: @material, material: @updated_material
    assert_redirected_to material_path(assigns(:material))
  end

  #DESTROY TEST
  test 'should destroy material owned by user' do
    sign_in users(:regular_user)
    assert_difference('Material.count', -1) do
      delete :destroy, id: @material
    end
    assert_redirected_to materials_path
  end

  test 'should not destroy material not owned by user' do
    sign_in users(:another_regular_user)
    puts 'destroyiiinnng---'
    assert_no_difference('Material.count') do
      delete :destroy, id: @material
    end
    assert_redirected_to materials_path
  end


  test 'breadcrumbs for materials index' do
    get :index
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li[class=active]', :text => /Materials/, :count => 1
    end
  end

  test 'breadcrumbs for showing material' do
    get :show, :id => @material
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Materials/, :count => 1 do
        assert_select 'a[href=?]', materials_url, :count => 1
      end
      assert_select 'li[class=active]', :text => /#{@material.title}/, :count => 1
    end
  end

  test 'breadcrumbs for editing material' do
    sign_in users(:regular_user)
    get :edit, id: @material
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Materials/, :count => 1 do
        assert_select 'a[href=?]', materials_url, :count => 1
      end
      assert_select 'li', :text => /#{@material.title}/, :count => 1 do
        assert_select 'a[href=?]', material_url(@material), :count => 1
      end
      assert_select 'li[class=active]', :text => /Edit/, :count => 1
    end
  end

  test 'breadcrumbs for creating new material' do
    sign_in users(:regular_user)
    get :new
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Materials/, :count => 1 do
        assert_select 'a[href=?]', materials_url, :count => 1
      end
      assert_select 'li[class=active]', :text => /New/, :count => 1
    end
  end

  test 'should find existing material by title' do
    post 'check_exists', :format => :json,  :title => @material.title
    assert_response :success
    assert_equal(JSON.parse(response.body)['title'], @material.title)
  end

  test 'should find existing material by url' do
    post 'check_exists', :format => :json,  :url => @material.url
    assert_response :success
    assert_equal(JSON.parse(response.body)['title'], @material.title)
  end

  test 'should return nothing when material does not exist' do
    post 'check_exists', :format => :json,  :title => 'This title should not exist'
    assert_response :success
    assert_equal(response.body, '')
  end

  # TODO: SOLR tests will not run on TRAVIS. Explore stratergy for testing solr
=begin
      test 'should return matching materials' do
        get 'index', :format => :json, :q => 'training'
        assert_response :success
        assert response.body.size > 0
      end

      test 'should return no matching materials' do
        get 'index', :format => :json, :q => 'kdfsajfklasdjfljsdfljdsfjncvmn'
        assert_response :success
        assert_equal(response.body,'[]')
        end
=end

end
