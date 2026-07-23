require 'test_helper'

class IdentitiesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should show identities for current user' do
    sign_in users(:existing_aaf_user)

    get :index, params: { user_id: users(:existing_aaf_user) }

    assert_response :success
    assert_select 'h1', 'Manage identities'
    assert_select 'tbody tr', minimum: 1
  end

  test "should not show another user's identities" do
    sign_in users(:regular_user)

    get :index, params: { user_id: users(:existing_aaf_user) }

    assert_response :forbidden
  end

  test 'should remove linked identity' do
    user = users(:regular_user)
    sign_in user
    identity = user.identities.create!(provider: 'oidc', uid: 'abc-123')

    assert_difference('Identity.count', -1) do
      delete :destroy, params: { user_id: user, id: identity }
    end

    assert_redirected_to user_identities_path(user)
    assert_equal 'Identity removed.', flash[:notice]
  end

  test 'should not remove last identity when account has no password' do
    user = users(:existing_aaf_user)
    sign_in user

    assert_no_difference('Identity.count') do
      delete :destroy, params: { user_id: user, id: user.identities.first }
    end

    assert_redirected_to user_identities_path(user)
    assert_equal 'You cannot remove your last identity because your account has no password.', flash[:notice]
  end
end
