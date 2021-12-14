require 'test_helper'

class InvitationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @controller = TessDevise::InvitationsController.new
    @user = users(:regular_user)
    @curator = users(:curator)
    @admin = users(:admin)
  end

  teardown do
    # TODO: reset as required
  end

  test 'new invitation access' do
    # public user
    get new_user_invitation_path
    assert_redirected_to root_path

    # regular user
    assert !@user.nil?, 'regular_user is nil.'
    sign_in @user
    get '/users/invitation/new'
    assert_redirected_to root_path
    sign_out @user

    # regular user
    assert !@curator.nil?, 'curator is nil.'
    sign_in @curator
    get :new
    assert_response :success
    sign_out @curator

    # admin user
    assert !@admin.nil?, 'admin is nil.'
    sign_in @admin
    get :new
    assert_response :success
    sign_out @admin
  end

end
