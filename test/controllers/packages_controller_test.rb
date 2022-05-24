require 'test_helper'

class PackagesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    mock_images
    @package = packages(:one)
    #u = users(:regular_user)
    #@package.user_id = u.id
    #@package.save!
    @updated_package = {
        title: 'New title',
        description: 'New description'
    }
  end
  #INDEX TESTS
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:packages)
  end

  test 'should get index as json' do
    get :index, format: :json
    assert_response :success
    assert_not_nil assigns(:packages)
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
    get :edit, params: { id: @package }
    assert_redirected_to new_user_session_path
  end

    #logged in but insufficient permissions = ERROR
  test 'should get edit for package owner' do
    sign_in @package.user
    get :edit, params: { id: @package }
    assert_response :success
  end

  test 'should get edit for admin' do
    #Owner of package logged in = SUCCESS
    sign_in users(:admin)
    get :edit, params: { id: @package }
    assert_response :success
  end

  test 'should not get edit page for non-owner user' do
    #Administrator = SUCCESS
    sign_in users(:another_regular_user)
    get :edit, params: { id: @package }
    assert :forbidden
  end

  #CREATE TEST
  test 'should create package for user' do
    sign_in users(:regular_user)
    assert_difference('Package.count') do
      post :create, params: { package: { title: @package.title, image_url: @package.image_url, description: @package.description } }
    end
    assert_redirected_to package_path(assigns(:package))
  end

  test 'should create package for admin' do
    sign_in users(:admin)
    assert_difference('Package.count') do
      post :create, params: { package: { title: @package.title, image_url: @package.image_url, description: @package.description } }
    end
    assert_redirected_to package_path(assigns(:package))
  end

  test 'should not create package for non-logged in user' do
    assert_no_difference('Package.count') do
      post :create, params: { package: { title: @package.title, image_url: @package.image_url, description: @package.description } }
    end
    assert_redirected_to new_user_session_path
  end

  #SHOW TEST
  test 'should show package' do
    get :show, params: { id: @package }
    assert_response :success
    assert assigns(:package)
  end

  test 'should show package as json' do
    get :show, params: { id: @package, format: :json }
    assert_response :success
    assert assigns(:package)
  end

  #UPDATE TEST
  test 'should update package' do
    sign_in @package.user
    patch :update, params: { id: @package, package: @updated_package }
    assert_redirected_to package_path(assigns(:package))
  end

  #DESTROY TEST
  test 'should destroy package owned by user' do
    sign_in @package.user
    assert_difference('Package.count', -1) do
      delete :destroy, params: { id: @package }
    end
    assert_redirected_to packages_path
  end

  test 'should destroy package when administrator' do
    sign_in users(:admin)
    assert_difference('Package.count', -1) do
      delete :destroy, params: { id: @package }
    end
    assert_redirected_to packages_path
  end

  test 'should not destroy package not owned by user' do
    sign_in users(:another_regular_user)
    assert_no_difference('Package.count') do
      delete :destroy, params: { id: @package }
    end
    assert_response :forbidden
  end


  #CONTENT TESTS
  #BREADCRUMBS
  test 'breadcrumbs for packages index' do
    get :index
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li[class=active]', :text => /Packages/, :count => 1
    end
  end

  test 'breadcrumbs for showing package' do
    get :show, params: { :id => @package }
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Packages/, :count => 1 do
        assert_select 'a[href=?]', packages_url, :count => 1
      end
      assert_select 'li[class=active]', :text => /#{@package.title}/, :count => 1
    end
  end

  test 'breadcrumbs for editing package' do
    sign_in users(:admin)
    get :edit, params: { id: @package }
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Packages/, :count => 1 do
        assert_select 'a[href=?]', packages_url, :count => 1
      end
      assert_select 'li', :text => /#{@package.title}/, :count => 1 do
        assert_select 'a[href=?]', package_url(@package), :count => 1
      end
      assert_select 'li[class=active]', :text => /Edit/, :count => 1
    end
  end

  test 'breadcrumbs for creating new package' do
    sign_in users(:regular_user)
    get :new
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Packages/, :count => 1 do
        assert_select 'a[href=?]', packages_url, :count => 1
      end
      assert_select 'li[class=active]', :text => /New/, :count => 1
    end
  end

  #OTHER CONTENT
  test 'package has correct tabs' do
    get :show, params: { :id => @package }
    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li.disabled', :count => 3 # This package has no events, materials or activity
    end

    packages(:with_resources).materials << materials(:good_material)
    packages(:with_resources).events << events(:one)

    get :show, params: { :id => packages(:with_resources) }
    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li' do
        assert_select 'a[data-toggle="tab"]', :count => 3 # Events, Materials, Activity (added the resources)
      end
    end
  end

  test 'package has correct layout' do
    get :show, params: { :id => @package }
    assert_response :success
    assert_select 'div.search-results-count', :count => 2 #Has results
    assert_select 'a.btn-info', :text => 'Back', :count => 1 #No Edit
    #Should not show when not logged in
    assert_select 'a.btn-primary[href=?]', edit_package_path(@package), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', package_path(@package), :count => 0 #No Edit

  end

  test 'do not show action buttons when not owner or admin' do
    sign_in users(:another_regular_user)
    get :show, params: { :id => @package }
    assert_select 'a.btn-primary[href=?]', edit_package_path(@package), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', package_path(@package), :count => 0 #No Edit
  end

  test 'show action buttons when owner' do
    sign_in @package.user
    get :show, params: { :id => @package }
    assert_select 'a.btn-primary[href=?]', edit_package_path(@package), :count => 1
    assert_select 'a.btn-danger[href=?]', package_path(@package), :text => 'Delete', :count => 1
  end

  test 'show action buttons when admin' do
    sign_in users(:admin)
    get :show, params: { :id => @package }
    assert_select 'a.btn-primary[href=?]', edit_package_path(@package), :count => 1
    assert_select 'a.btn-danger[href=?]', package_path(@package), :text => 'Delete', :count => 1
  end

  #API Actions
  test "should remove materials from package" do
    sign_in users(:regular_user)
    package = packages(:with_resources)
    package.materials = [materials(:biojs), materials(:interpro)]
    package.save!
    assert_difference('package.materials.count', -2) do
      patch :update, params: { package: { material_ids: [''] }, id: package.id }
    end
  end     
  
  test "should add events to package" do
    sign_in users(:regular_user)
    assert_difference('@package.events.count', +2) do
      patch :update, params: { package: { event_ids: [events(:one), events(:two)]}, id: @package.id }
    end
  end
  
  test "should remove events from package" do
    sign_in users(:regular_user)
    package = packages(:with_resources)
    package.events = [events(:one), events(:two)]
    package.save!
    assert_difference('package.events.count', -2) do
      patch :update, params: { package: { event_ids: ['']}, id: package.id }
    end
  end

  test 'should not allow access to private packages' do
    get :show, params: { id: packages(:secret_package) }
    assert_response :forbidden
  end

  test 'should allow access to private packages if privileged' do
    sign_in users(:regular_user)
    get :show, params: { id: packages(:secret_package) }
    assert_response :success
  end

  test 'should hide private packages from index' do
    get :index
    assert_response :success
    assert_not_includes assigns(:packages).map(&:id), packages(:secret_package).id
  end

  test 'should not hide private packages from index from package owner' do
    sign_in users(:regular_user)
    get :index
    assert_response :success
    assert_includes assigns(:packages).map(&:id), packages(:secret_package).id
  end

  test 'should not hide private packages from index from admin' do
    sign_in users(:admin)
    get :index
    assert_response :success
    assert_includes assigns(:packages).map(&:id), packages(:secret_package).id
  end

end
