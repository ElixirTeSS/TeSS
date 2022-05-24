require 'test_helper'

module TessDevise
  class RegistrationsControllerTest < ActionController::TestCase

    include Devise::Test::ControllerHelpers

    setup do
      request.env['devise.mapping'] = Devise.mappings[:user]
    end

    test 'should register user' do
       assert_difference('User.count') do
         post :create, params: {
             user: {
                 username: 'mileyfan1997',
                 email: 'h4nn4hm0nt4n4@example.com',
                 password: '12345678',
                 password_confirmation: '12345678',
                 processing_consent: '1'
             }
         }
       end

       assert_redirected_to root_path
    end

    test 'should not register user when passwords do not match' do
      assert_no_difference('User.count') do
        post :create, params: {
            user: { username: 'mileyfan1997',
                    email: 'h4nn4hm0nt4n4@example.com',
                    password: '12345678',
                    password_confirmation: '353278532',
                    processing_consent: '1'
            }
        }
      end
    end

    test 'should not register user when captcha failed' do
      Recaptcha.with_configuration(skip_verify_env: []) do
        assert_no_difference('User.count') do
          post :create, params: {
              user: {
                  username: 'mileyfan1997',
                  email: 'h4nn4hm0nt4n4@example.com',
                  password: '12345678',
                  password_confirmation: '12345678',
                  processing_consent: '1'
              }
          }
        end
      end
    end

    test 'should not register user when no consent given' do
       assert_no_difference('User.count') do
         post :create, params: {
             user: {
                 username: 'mileyfan1997',
                 email: 'h4nn4hm0nt4n4@example.com',
                 password: '12345678',
                 password_confirmation: '12345678' }
         }
       end

       assert assigns(:user).errors[:base].first.include?('processing')
    end

    test 'should redirect to user page after changing password' do
      user = users(:regular_user)
      sign_in user

      put :update, params: {
          user: {
              username: user.username,
              email: user.email,
              password: '12345678',
              password_confirmation: '12345678',
              current_password: 'hello'
          }
      }

      assert_redirected_to assigns(:user)
    end

    test 'should update user email' do
      user = users(:regular_user)
      sign_in user

      put :update, params: {
          user: {
              username: user.username,
              email: "123#{user.email}",
              current_password: 'hello'
          }
      }

      assert_redirected_to assigns(:user)
    end

    test 'should get account management page if logged in' do
      user = users(:regular_user)
      sign_in user

      get :edit

      assert_response :success
    end

    test 'should not get account management page if not logged in' do
      get :edit

      assert_redirected_to new_user_session_path
    end

    test 'should update username for AAF user without requiring current password' do
      user = users(:existing_aaf_user)
      sign_in user

      assert user.using_omniauth?

      put :update, params: { user: { username: 'cooldude99' } }
      assert_redirected_to assigns(:user)
    end
  end
end
