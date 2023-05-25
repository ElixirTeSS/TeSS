# frozen_string_literal: true

require 'test_helper'

class TrainersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'get all trainers' do
    get :index

    assert_response :success
    trainers = assigns(:trainers)

    refute_nil trainers
    assert_equal 1, trainers.size
  end
end
