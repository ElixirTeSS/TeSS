require 'test_helper'

class AboutControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get first about page' do
    get :tess
    assert_response :success
  end

  test 'should get about us' do
    get :us
    assert_response :success
  end


  test 'should get about registering' do
    get :registering
    assert_response :success
  end


  test 'should get about developers' do
    get :developers
    assert_response :success
  end

end
