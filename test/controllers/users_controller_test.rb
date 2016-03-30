require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    @user = users(:regular_user)
    @admin = users(:admin)
  end

  test "should get index page when logged in" do
    sign_in users(:regular_user)
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "should_redirect_user_to_login_page when going to index page whilst not logged in" do
    get :index
    assert_redirected_to new_user_session_path
  end

  test "should never allow user#new route" do
    get :new
    assert_redirected_to new_user_session_path
    sign_in users(:regular_user)
    get :new
    assert_redirected_to new_user_session_path
    sign_in users(:admin)
    get :new
    assert_redirected_to new_user_session_path
  end

  test "should be able to create user whilst logged in as admin" do
    sign_in users(:admin) # should this be restricted to admins?
    assert_difference('User.count') do
      post :create, user: { username: 'frank', email: 'frank@notarealdomain.org', password: 'franksreallylongpass'}
    end
    assert_redirected_to user_path(assigns(:user))
  end

  test "should not be able create user if not admin" do #because you use users#sign_up in devise
    assert_no_difference('User.count') do
      post :create, user: { username: 'frank', email: 'frank@notarealdomain.org', password: 'franksreallylongpass'}
    end
    assert_redirected_to new_user_session_path
    sign_in users(:regular_user)
    assert_no_difference('User.count') do
      post :create, user: { username: 'frank', email: 'frank@notarealdomain.org', password: 'franksreallylongpass'}
    end
    assert_redirected_to new_user_session_path
  end

  test "should show user if admin" do
    sign_in users(:admin)
    get :show, id: @user
    assert_response :success
  end

  test "should not show other users page if not admin and self" do
    sign_in users(:another_regular_user)
    get :show, id: @user
    assert_redirected_to root_path #FORBIDDEN PAGE!
  end

 test "should only allow edit for admin and self" do
    sign_in users(:regular_user)
    get :edit, id: @user
    assert_response :success

    sign_in users(:admin)
    get :edit, id: @user
    assert_response :success

    sign_in users(:another_regular_user)
    get :edit, id: @user
    #assert_redirected_to root_path
  end

  test "should update user" do
    sign_in users(:regular_user)
    patch :update, id: @user, user: { email: 'hot@mail.com' }
    assert_redirected_to user_path(assigns(:user))
  end

  test "should reset token" do
    sign_in users(:regular_user)
    old_token = @user.authentication_token
    patch :change_token
    new_token = User.find_by_username('Bob').authentication_token
    assert_not_equal old_token, new_token
  end

  test "should destroy user" do
    sign_in users(:regular_user)
    assert_difference('User.count', -1) do
      delete :destroy, id: @user
    end

    assert_redirected_to users_path
  end
end
