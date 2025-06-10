require 'test_helper'

class SpacesControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    mock_ingestions
    @space = spaces(:plants)
    @space_params = {
      space: {
        title: 'My New Space',
        host: 'newspace.mytess.training'
      }
    }
  end

  # INDEX Tests
  test 'public should get index' do
    get :index
    assert_response :success
    assert_not_empty assigns(:spaces), 'spaces is empty'
  end

  test 'site admin should get index' do
    sign_in users(:admin)
    get :index
    assert_response :success
    assert_not_empty assigns(:spaces), 'spaces is empty'
  end

  # SHOW Tests
  test 'public should show space' do
    get :show, params: { id: @space }
    assert_response :success
    assert assigns(:space)
    assert_select 'h2', { text: 'TeSS Plants Community' }
  end

  test 'owner should show space' do
    sign_in @space.user
    get :show, params: { id: @space }
    assert_response :success
    assert assigns(:space)
    assert_select 'a.btn[href=?]', edit_space_path(@space), count: 1
    assert_select 'a.btn[href=?]', space_path(@space), text: 'Delete', count: 0
  end

  test 'space admin should show space' do
    sign_in users(:space_admin)
    get :show, params: { id: @space }
    assert_response :success
    assert assigns(:space)
    assert_select 'a.btn[href=?]', edit_space_path(@space), count: 1
    assert_select 'a.btn[href=?]', space_path(@space), text: 'Delete', count: 0
  end

  test 'site admin should show space' do
    sign_in users(:admin)
    get :show, params: { id: @space }
    assert_response :success
    assert assigns(:space)
    assert_select 'a.btn[href=?]', edit_space_path(@space), count: 1
    assert_select 'a.btn[href=?]', space_path(@space), text: 'Delete', count: 1
  end

  # NEW Tests
  test 'public should not get new' do
    get :new
    assert_redirected_to new_user_session_path
  end

  test 'site admin should get new' do
    sign_in users(:admin)
    get :new
    assert_response :success
  end

  test 'space admin should not get new' do
    sign_in users(:space_admin)
    get :new
    assert_response :forbidden
  end

  # EDIT Tests
  test 'public should not get edit' do
    get :edit, params: { id: @space }
    assert_redirected_to new_user_session_path
  end

  test 'owner should get edit' do
    sign_in @space.user
    get :edit, params: { id: @space }
    assert_response :success
  end
  
  test 'owner should not get edit for other space' do
    sign_in @space.user
    get :edit, params: { id: spaces(:other) }
    assert_response :forbidden
  end

  test 'space admin should get edit' do
    sign_in users(:space_admin)
    get :edit, params: { id: @space }
    assert_response :success
  end

  test 'space admin should not get edit for other space' do
    sign_in users(:space_admin)
    get :edit, params: { id: spaces(:other) }
    assert_response :forbidden
  end

  test 'site admin should get edit' do
    sign_in users(:admin)
    get :edit, params: { id: @space }
    assert_response :success
  end

  # CREATE Tests
  test 'public should not create space' do
    assert_no_difference 'Space.count' do
      post :create, params: @space_params
    end
    assert_redirected_to new_user_session_path
  end

  test 'user cannot create new space' do
    sign_in @space.user
    refute_permitted SpacePolicy, @space.user, :create?, Space
    assert_no_difference 'Space.count' do
      post :create, params: @space_params
    end
    assert_response :forbidden
  end

  test 'space admin cannot create new space' do
    sign_in users(:space_admin)
    refute_permitted SpacePolicy, @space.user, :create?, Space
    assert_no_difference 'Space.count' do
      post :create, params: @space_params
    end
    assert_response :forbidden
  end

  test 'site admin can create space' do
    sign_in users(:admin)
    assert_difference 'Space.count', 1 do
      post :create, params: @space_params
    end
    assert_redirected_to space_path(assigns(:space))
  end

  # UPDATE Tests
  test 'public should not update space' do
    patch :update, params: { id: @space, space: @update_params }
    assert_redirected_to new_user_session_path
  end

  test 'unaffiliated user should not update space' do
    sign_in users(:another_regular_user)
    patch :update, params: { id: @space, space: @update_params }
    assert_response :forbidden
  end

  test 'user should update owned space' do
    sign_in @space.user
    patch :update, params: { id: @space, space: { title: 'New Title', host: 'newhost.mytess.golf' } }
    assert_redirected_to space_path(assigns(:space))
    assert_equal 'New Title', assigns(:space).title
    assert_equal 'plants.mytess.training', assigns(:space).host, 'Non-admin user should not be able to modify host'
  end

  test 'space admin should update owned space' do
    sign_in users(:space_admin)
    patch :update, params: { id: @space, space: { title: 'New Title', host: 'newhost.mytess.golf' } }
    assert_redirected_to space_path(assigns(:space))
    assert_equal 'New Title', assigns(:space).title
    assert_equal 'plants.mytess.training', assigns(:space).host, 'Non-admin user should not be able to modify host'
  end

  test 'site admin should update space' do
    sign_in users(:admin)
    assert_no_difference 'Space.count' do
      patch :update, params: { id: @space, space: { title: 'New Title', host: 'newhost.mytess.golf' } }
      assert_redirected_to space_path(assigns(:space))
    end
    assert_equal 'New Title', assigns(:space).title
    assert_equal 'newhost.mytess.golf', assigns(:space).host
  end

  # DESTROY Tests
  test 'public should not destroy space' do
    assert_no_difference 'Space.count' do
      delete :destroy, params: { id: @space }
    end
    assert_redirected_to new_user_session_path
  end

  test 'owner cannot destroy space' do
    sign_in @space.user
    assert_no_difference 'Space.count' do
      delete :destroy, params: { id: @space }
      assert_response :forbidden
    end
  end

  test 'space admin cannot destroy space' do
    sign_in users(:space_admin)
    assert_no_difference 'Space.count' do
      delete :destroy, params: { id: @space }
      assert_response :forbidden
    end
  end

  test 'site admin can destroy space' do
    sign_in users(:admin)
    assert_difference 'Space.count', -1 do
      post :destroy, params: { id: @space }
      assert_redirected_to spaces_path
      assert_equal 'Space was successfully deleted.', flash[:notice]
    end
  end

  test 'space admin can assign new space admins' do
    existing_admin = users(:space_admin)
    sign_in existing_admin
    new_admin = users(:regular_user)
    assert_difference('SpaceRole.count', 1) do # space_admin is already an admin, so only increases by 1
      patch :update, params: { id: @space, space: { title: 'New Title', administrator_ids: [existing_admin.id, new_admin.id] } }
      assert_redirected_to space_path(assigns(:space))
    end

    admins = assigns(:space).administrators
    assert_includes admins, existing_admin
    assert_includes admins, new_admin
  end
end
