require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    @user = users(:regular_user)
    @admin = users(:admin)
  end

  test "should get index" do
    sign_in users(:regular_user)
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "should get new" do
    sign_in users(:regular_user)
    get :new
    assert_response :success
  end

  test "should create user" do
    sign_in users(:admin) # should this be restricted to admins?
    assert_difference('User.count') do
      post :create, user: { username: 'frank', email: 'frank@notarealdomain.org', password: 'franksreallylongpass'}
    end

    assert_redirected_to user_path(assigns(:user))
  end

  test "should show user" do
    sign_in users(:admin)
    get :show, id: @user
    assert_response :success
  end

  test "should not show user" do
    sign_in users(:regular_user)
    get :show, id: @user
    assert_redirected_to root_path
  end

  test "should get edit" do
    sign_in users(:admin)
    get :edit, id: @user
    assert_response :success
  end

 test "should not get edit" do
    sign_in users(:regular_user)
    get :edit, id: @user
    assert_redirected_to root_path
  end

  test "should update user" do
    sign_in users(:regular_user)
    patch :update, id: @user, user: { email: 'hot@mail.com' }
    assert_redirected_to user_path(assigns(:user))
  end

  test "should destroy user" do
    sign_in users(:regular_user)
    assert_difference('User.count', -1) do
      delete :destroy, id: @user
    end

    assert_redirected_to users_path
  end
end
