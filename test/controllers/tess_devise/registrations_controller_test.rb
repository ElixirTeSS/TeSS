require 'test_helper'

module TessDevise
  class RegistrationsControllerTest < ActionController::TestCase

    include Devise::Test::ControllerHelpers

    setup do
      request.env['devise.mapping'] = Devise.mappings[:user]
    end

    test 'should register user' do
      assert_difference('User.count') do
        post :create, user: { username: 'mileyfan1997',
                              email: 'h4nn4hm0nt4n4@example.com',
                              password: '12345678',
                              password_confirmation: '12345678' }
      end

      assert_redirected_to root_path
    end

    test 'should not register user when passwords do not match' do
      assert_no_difference('User.count') do
        post :create, user: { username: 'mileyfan1997',
                              email: 'h4nn4hm0nt4n4@example.com',
                              password: '12345678',
                              password_confirmation: '353278532' }
      end
    end

    test 'should not register user when captcha failed' do
      Recaptcha.with_configuration(skip_verify_env: []) do
        assert_no_difference('User.count') do
          post :create, user: { username: 'mileyfan1997',
                                email: 'h4nn4hm0nt4n4@example.com',
                                password: '12345678',
                                password_confirmation: '12345678' }
        end
      end
    end

    test 'should redirect to user page after changing password' do
      user = users(:regular_user)
      sign_in user

      put :update, user: { username: user.username,
                           email: user.email,
                           password: '12345678',
                           password_confirmation: '12345678',
                           current_password: 'hello' }

      assert_redirected_to assigns(:user)
    end

    test 'should update user email' do
      user = users(:regular_user)
      sign_in user

      put :update, user: { username: user.username,
                           email: "123#{user.email}",
                           current_password: 'hello' }

      assert_redirected_to assigns(:user)
    end
  end
end
