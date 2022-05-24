require 'test_helper'

module TessDevise
  class InvitationsControllerTest < ActionController::TestCase

    include Devise::Test::ControllerHelpers

    setup do
      request.env['devise.mapping'] = Devise.mappings[:user]
    end

    test 'new invitation access for registered user' do
      assert !users(:regular_user).nil?, 'regular_user is nil.'
      sign_in users(:regular_user)

      get :new
      assert_response :redirect
      assert_redirected_to root_path
      sign_out users(:regular_user)
    end

    test 'new invitation access for curator' do
      assert !users(:curator).nil?, 'curator is nil.'
      sign_in users(:curator)
      get :new
      assert_response :success
      sign_out users(:curator)
    end

    test 'new invitation access for admin' do
      assert !users(:admin).nil?, 'admin is nil.'
      sign_in users(:admin)
      get :new
      assert_response :success
      sign_out users(:admin)
    end

    test 'new invitation access for public' do
      get :new
      assert_response :redirect
      assert_redirected_to new_user_session_path
    end

=begin
        test 'create invitation' do
          sign_in users(:curator)
          assert_difference('User.count') do
            post :create, params: {
              email: 'invite@test.domain.com'
            }
          end
          assert_response :success
          assert_redirected_to root_path
          sign_out users(:curator)
        end
=end
  end
end