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
  end
end
