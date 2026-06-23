require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @group = groups(:one)

    # Create membership fixtures in-memory so we don't need a separate YAML file.
    # owner_user    → member + owner  of @group
    # member_user   → member (non-owner) of @group
    # outsider_user → not a member at all
    @owner_user   = users(:regular_user)
    @member_user  = users(:another_regular_user)
    @outsider     = users(:curator)
    @admin        = users(:admin)

    @group.group_memberships.find_or_create_by!(user: @owner_user)  { |m| m.owner = true }
    @group.group_memberships.find_or_create_by!(user: @member_user) { |m| m.owner = false }
  end

  # ---------------------------------------------------------------------------
  # INDEX  (public)
  # ---------------------------------------------------------------------------

  test 'should get index when not logged in' do
    get :index
    assert_response :success
  end

  test 'should get index when logged in' do
    sign_in @outsider
    get :index
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # SHOW  (members + admins only)
  # ---------------------------------------------------------------------------

  test 'should deny show to anonymous user' do
    get :show, params: { id: @group }
<<<<<<< HEAD
    assert_response :forbidden
=======
    assert_response :redirect
>>>>>>> 75c094a5a1a472c2b736352b0ba315a6c9819449
  end

  test 'should deny show to outsider (non-member)' do
    sign_in @outsider
    get :show, params: { id: @group }
<<<<<<< HEAD
    assert_response :forbidden
=======
    assert_response :redirect
>>>>>>> 75c094a5a1a472c2b736352b0ba315a6c9819449
  end

  test 'should allow show to group member' do
    sign_in @member_user
    get :show, params: { id: @group }
    assert_response :success
  end

  test 'should allow show to group owner' do
    sign_in @owner_user
    get :show, params: { id: @group }
    assert_response :success
  end

  test 'should allow show to admin' do
    sign_in @admin
    get :show, params: { id: @group }
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # NEW / CREATE  (admin only)
  # ---------------------------------------------------------------------------

  test 'should deny new to anonymous user' do
    get :new
    assert_redirected_to new_user_session_path
  end

  test 'should deny new to regular member' do
    sign_in @member_user
    get :new
<<<<<<< HEAD
    assert_response :forbidden
=======
    assert_response :redirect
>>>>>>> 75c094a5a1a472c2b736352b0ba315a6c9819449
  end

  test 'should deny new to group owner (non-admin)' do
    sign_in @owner_user
    get :new
<<<<<<< HEAD
    assert_response :forbidden
=======
    assert_response :redirect
>>>>>>> 75c094a5a1a472c2b736352b0ba315a6c9819449
  end

  test 'should allow new for admin' do
    sign_in @admin
    get :new
    assert_response :success
  end

  test 'should deny create to non-admin' do
    sign_in @member_user
    assert_no_difference('Group.count') do
      post :create, params: { group: { title: 'New group' } }
    end
<<<<<<< HEAD
    assert_response :forbidden
=======
    assert_response :redirect
>>>>>>> 75c094a5a1a472c2b736352b0ba315a6c9819449
  end

  test 'should allow admin to create group' do
    sign_in @admin
    assert_difference('Group.count', 1) do
      post :create, params: { group: { title: 'Admin new group' } }
    end
    assert_redirected_to group_url(Group.last)
  end

  # ---------------------------------------------------------------------------
  # EDIT / UPDATE  (owner + admin)
  # ---------------------------------------------------------------------------

  test 'should deny edit to anonymous user' do
    get :edit, params: { id: @group }
    assert_redirected_to new_user_session_path
  end

  test 'should deny edit to outsider' do
    sign_in @outsider
    get :edit, params: { id: @group }
<<<<<<< HEAD
    assert_response :forbidden
=======
    assert_response :redirect
>>>>>>> 75c094a5a1a472c2b736352b0ba315a6c9819449
  end

  test 'should deny edit to non-owner member' do
    sign_in @member_user
    get :edit, params: { id: @group }
<<<<<<< HEAD
    assert_response :forbidden
=======
    assert_response :redirect
>>>>>>> 75c094a5a1a472c2b736352b0ba315a6c9819449
  end

  test 'should allow edit for group owner' do
    sign_in @owner_user
    get :edit, params: { id: @group }
    assert_response :success
  end

  test 'should allow edit for admin' do
    sign_in @admin
    get :edit, params: { id: @group }
    assert_response :success
  end

  test 'should deny update to non-owner member' do
    sign_in @member_user
    patch :update, params: { id: @group, group: { title: 'Hacked title' } }
<<<<<<< HEAD
    assert_response :forbidden
=======
    assert_response :redirect
>>>>>>> 75c094a5a1a472c2b736352b0ba315a6c9819449
    assert_not_equal 'Hacked title', @group.reload.title
  end

  test 'should allow owner to update group' do
    sign_in @owner_user
    patch :update, params: { id: @group, group: { title: 'Owner updated title' } }
    assert_redirected_to group_url(@group)
    assert_equal 'Owner updated title', @group.reload.title
  end

  test 'should allow admin to update group' do
    sign_in @admin
    patch :update, params: { id: @group, group: { title: 'Admin updated title' } }
    assert_redirected_to group_url(@group)
    assert_equal 'Admin updated title', @group.reload.title
  end

  test 'should deny update via JSON API even for owner' do
    sign_in @owner_user
    patch :update, params: { id: @group, group: { title: 'API attempt' } },
                   as: :json
<<<<<<< HEAD
    assert_response :forbidden
=======
    assert_response :redirect
>>>>>>> 75c094a5a1a472c2b736352b0ba315a6c9819449
    assert_not_equal 'API attempt', @group.reload.title
  end

  # ---------------------------------------------------------------------------
  # DESTROY  (admin only)
  # ---------------------------------------------------------------------------

  test 'should deny destroy to anonymous user' do
    assert_no_difference('Group.count') do
      delete :destroy, params: { id: @group }
    end
    assert_redirected_to new_user_session_path
  end

  test 'should deny destroy to group owner (non-admin)' do
    sign_in @owner_user
    assert_no_difference('Group.count') do
      delete :destroy, params: { id: @group }
    end
<<<<<<< HEAD
    assert_response :forbidden
=======
    assert_response :redirect
>>>>>>> 75c094a5a1a472c2b736352b0ba315a6c9819449
  end

  test 'should allow admin to destroy group' do
    sign_in @admin
    assert_difference('Group.count', -1) do
      delete :destroy, params: { id: @group }
    end
    assert_redirected_to groups_url
  end

  test 'should deny destroy via JSON API even for admin' do
    sign_in @admin
    assert_no_difference('Group.count') do
      delete :destroy, params: { id: @group }, as: :json
    end
<<<<<<< HEAD
    assert_response :forbidden
=======
    assert_response :redirect
>>>>>>> 75c094a5a1a472c2b736352b0ba315a6c9819449
  end
end