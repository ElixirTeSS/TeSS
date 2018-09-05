require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    mock_images
    @user = users(:regular_user)
    @admin = users(:admin)
  end

  test 'should get index page for everyone' do
    get :index
    assert_response :success
    sign_in users(:regular_user)
    assert_not_nil assigns(:users)
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test 'should get index as json-api' do
    get :index, params: { format: :json_api }
    assert_response :success
    assert_not_nil assigns(:users)
    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert body['data'].any?
    assert_equal users_path, body['links']['self']
  end

  # User new is handled by devise
  test "should never allow user new route" do
    get :new
    assert_redirected_to new_user_session_path
    sign_in users(:regular_user)
    get :new
    assert_response :forbidden
    sign_in users(:admin)
    get :new
    assert_response :forbidden
  end

  test "should be able to create user whilst logged in as admin" do
    sign_in users(:admin) # should this be restricted to admins?
    assert_difference('User.count') do
      post :create, params: {
          user: { username: 'frank', email: 'frank@notarealdomain.org', password: 'franksreallylongpass'}
      }
    end
    assert_redirected_to user_path(assigns(:user))
  end

  test "should not be able create user if not admin" do #because you use users#sign_up in devise
    assert_no_difference('User.count') do
      post :create, params: { user: { username: 'frank', email: 'frank@notarealdomain.org', password: 'franksreallylongpass'} }
    end
    assert_redirected_to new_user_session_path
    sign_in users(:regular_user)
    assert_no_difference('User.count') do
      post :create, params: { user: { username: 'frank', email: 'frank@notarealdomain.org', password: 'franksreallylongpass'} }
    end
    assert_response :forbidden
  end

  test "should show user if admin" do
    sign_in users(:admin)
    get :show, params: { id: @user }
    assert_response :success
  end

  test "should show other users page if not admin or self" do
    sign_in users(:another_regular_user)
    get :show, params: { id: @user }
    assert_response :success #FORBIDDEN PAGE!?
  end

  test "should show user with email address as username" do
    user = users(:email_address_user)
    sign_in user
    get :show, params: { id: user }
    assert_response :success
  end

  test "should show user as json" do
    sign_in users(:another_regular_user)
    get :show, params: { id: @user, format: 'json' }
    assert_response :success #FORBIDDEN PAGE!?
  end

  test 'should show user as json-api' do
    get :show, params: { id: @user, format: :json_api }
    assert_response :success
    assert assigns(:user)

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert_equal @user.profile.firstname, body['data']['attributes']['firstname']
    assert_equal user_path(assigns(:user)), body['data']['links']['self']
  end

  test "should only allow edit for admin and self" do
    sign_in users(:regular_user)
    get :edit, params: { id: @user }
    assert_response :success

    sign_in users(:admin)
    get :edit, params: { id: @user }
    assert_response :success

    sign_in users(:another_regular_user)
    get :edit, params: { id: @user }
    #assert_redirected_to root_path
  end

  test "should update profile" do
    sign_in users(:regular_user)
    patch :update, params: { id: @user, user: { profile_attributes: { email: 'hot@mail.com'} } }
    assert_redirected_to user_path(assigns(:user))
  end

  test "should reset token" do
    sign_in users(:regular_user)
    old_token = @user.authentication_token
    patch :change_token, params: { id: @user }
    new_token = User.find_by_username('Bob').authentication_token
    assert_not_equal old_token, new_token
  end

  test "should destroy user" do
    sign_in @user

    # Create default user that will be used as the new 'owner' of objects
    # after @user/real owner is destroyed. We are not really using it here
    # just making sure it is already in the DB so we can check number of users
    # after @user is deleted
    User.get_default_user

    assert_difference('User.count', -1) do
      delete :destroy, params: { id: @user }
    end
    assert_redirected_to users_path
  end

  test 'should change user role' do
    sign_in @admin
    assert_not_equal roles(:admin), @user.role

    patch :update, params: { id: @user, user: { role_id: roles(:admin).id } }

    assert_redirected_to user_path(assigns(:user))
    assert_equal roles(:admin), assigns(:user).role
  end

  test 'should change user role as js' do
    sign_in @admin
    assert_not_equal roles(:admin), @user.role

    patch :update, params: { id: @user, user: { role_id: roles(:admin).id }, format: :js }

    assert_response :success
    assert_equal roles(:admin), assigns(:user).role
  end

  test 'should not change user role if not an admin' do
    sign_in @user
    assert_not_equal roles(:admin), @user.role

    patch :update, params: { id: @user, user: { profile_attributes: { firstname: 'George' }, role_id: roles(:admin).id } }

    assert_redirected_to user_path(assigns(:user))
    assert_not_equal roles(:admin), assigns(:user).role
    assert_equal 'George', assigns(:user).profile.firstname
  end

  test 'should not update user if curator' do
    sign_in users(:curator)
    assert_not_equal roles(:curator), @user.role

    patch :update, params: { id: @user, user: { profile_attributes: { firstname: 'George' }, role_id: roles(:admin).id } }

    assert_response :forbidden
    assert_not_equal roles(:curator), assigns(:user).role
    assert_not_equal 'George', assigns(:user).profile.firstname
  end

  test 'should show ban info to admin' do
    user = users(:shadowbanned_user)
    sign_in users(:admin)
    get :show, params: { id: user }
    assert_response :success
    assert_select '.ban-info', count: 1
  end

  test 'should not show ban info to user' do
    user = users(:shadowbanned_user)
    sign_in user
    get :show, params: { id: user }
    assert_response :success
    assert_select '.ban-info', count: 0
  end
end
