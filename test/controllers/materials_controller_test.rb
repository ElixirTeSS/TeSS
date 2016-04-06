require 'test_helper'

class MaterialsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  setup do
    @material = materials(:good_material)
    u = users(:regular_user)
    @material.user_id = u.id
    @material.save!
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
  test 'should not get edit page for not logged in users' do
    #Not logged in = Redirect to login
    get :edit, id: @material
    assert_redirected_to new_user_session_path
  end

    #logged in but insufficient permissions = ERROR
  test 'should get edit for material owner' do
    sign_in users(:regular_user)
    get :edit, id: @material
    assert_response :success
  end

  test 'should get edit for admin' do
    #Owner of material logged in = SUCCESS
    sign_in users(:admin)
    get :edit, id: @material
    assert_response :success
  end

  test 'should not get edit page for non-owner user' do
    #Administrator = SUCCESS
    sign_in users(:another_regular_user)
    get :edit, id: @material
    assert :forbidden
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
    assert assigns(:material)
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

  test 'should destroy material when administrator' do
    sign_in users(:admin)
    assert_difference('Material.count', -1) do
      delete :destroy, id: @material
    end
    assert_redirected_to materials_path
  end

  test 'should not destroy material not owned by user' do
    sign_in users(:another_regular_user)
    assert_no_difference('Material.count') do
      delete :destroy, id: @material
    end
    assert_response :forbidden
  end


  #CONTENT TESTS
  #BREADCRUMBS
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

  #OTHER CONTENT
  test 'material has correct tabs' do
    get :show, :id => @material
    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li' do
        assert_select 'a[data-toggle="tab"]', :count => 3
      end
    end
  end

  test 'material has correct layout' do
    get :show, :id => @material
    assert_response :success
    assert_select 'h2', :text => @material.title #Has Title
    assert_select 'a.h5[href=?]', @material.url #Has plain written URL
    assert_select 'a.btn-info[href=?]', materials_path, :count => 1 #Back button
    assert_select 'button.btn-success', :text => "View material", :count => 1 do
      assert_select 'a[href=?]', @material.url, :count => 1 #View Material button
    end
    #Should not show when not logged in
    assert_select 'a.btn-primary[href=?]', edit_material_path(@material), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', material_path(@material), :count => 0 #No Edit
  end

  test 'do not show action buttons when not owner or admin' do
    sign_in users(:another_regular_user)
    get :show, :id => @material
    assert_select 'a.btn-primary[href=?]', edit_material_path(@material), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', material_path(@material), :count => 0 #No Edit
  end

  test 'show action buttons when owner' do
    sign_in users(:regular_user)
    get :show, :id => @material
    assert_select 'a.btn-primary[href=?]', edit_material_path(@material), :count => 1
    assert_select 'a.btn-danger[href=?]', material_path(@material), :text => 'Delete', :count => 1
  end

  test 'show action buttons when admin' do
    sign_in users(:admin)
    get :show, :id => @material
    assert_select 'a.btn-primary[href=?]', edit_material_path(@material), :count => 1
    assert_select 'a.btn-danger[href=?]', material_path(@material), :text => 'Delete', :count => 1
  end

  #API Actions
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

  test 'should display filters on index' do
    get :index
    assert_select 'h4.nav-heading', :text => /Content provider/, :count => 0
    assert_select 'div.list-group-item', :count => Material.count
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
