require 'test_helper'

class TrainersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'get all trainers' do
    get :index
    assert_response :success
    trainers = assigns(:trainers)
    assert_not_nil trainers
    assert_equal 1, trainers.size
  end

end
