require 'test_helper'

class PackagesControllerTest < ActionController::TestCase
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
      post :create, package: { description: @package.description, image_url: @package.image_url, name: @package.name, public: @package.public }
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
    patch :update, id: @package, package: { description: @package.description, image_url: @package.image_url, name: @package.name, public: @package.public }
    assert_redirected_to package_path(assigns(:package))
  end

  test "should destroy package" do
    sign_in users(:regular_user)
    assert_difference('Package.count', -1) do
      delete :destroy, id: @package
    end

    assert_redirected_to packages_path
  end
end
