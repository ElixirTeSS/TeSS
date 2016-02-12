require 'test_helper'

class PackagesControllerTest < ActionController::TestCase

  include Devise::TestHelpers


  setup do
    @package = packages(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:packages)
  end

  test "should get new" do
    sign_in users(:regular_user)
    get :new
    assert_response :success
  end

  test "should create package" do
    sign_in users(:regular_user)
    assert_difference('Package.count') do
      post :create, package: { description: @package.description, image_url: @package.image_url, title: @package.title, public: @package.public }
    end

    assert_redirected_to package_path(assigns(:package))
  end

  test "should show package" do
    get :show, id: @package
    assert_response :success
  end

  test "should get edit" do
    sign_in users(:regular_user)
    get :edit, id: @package
    assert_response :success
  end

  test "should update package" do
    sign_in users(:regular_user)
    patch :update, id: @package, package: { description: @package.description, image_url: @package.image_url, title: @package.title, public: @package.public }
    assert_redirected_to package_path(assigns(:package))
  end

  test "should destroy package" do
    sign_in users(:regular_user)
    assert_difference('Package.count', -1) do
      delete :destroy, id: @package
    end
    assert_redirected_to packages_path
  end

  test "should_add_materials_to_package" do
    sign_in users(:regular_user)
    assert_difference('@package.materials.count', +2) do
      post :update_package_resources, package: {material_ids: [materials(:biojs).id, materials(:interpro).id]}, package_id: @package.id
    end
  end
  test "should_remove_materials_from_package" do
    sign_in users(:regular_user)
    package = packages(:with_resources)
    post :update_package_resources, package: {material_ids: [materials(:biojs).id, materials(:interpro).id]}, package_id: package.id
    assert_difference('package.materials.count', -2) do
      post :update_package_resources, package: {material_ids: []}, package_id: package.id
    end
  end
  test "should_add_events_to_package" do
    sign_in users(:regular_user)
    assert_difference('@package.events.count', +2) do
      post :update_package_resources, package: { event_ids: [events(:one), events(:two)]}, package_id: @package.id
    end
  end
  test "should_remove_events_from_package" do
    sign_in users(:regular_user)
    package = packages(:with_resources)
    post :update_package_resources, package: { event_ids: [events(:one), events(:two)]}, package_id: package.id
    assert_difference('package.events.count', -2) do
      post :update_package_resources, package: { event_ids: []}, package_id: package.id
    end
  end
end
