require 'test_helper'

class ActivitiesControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  test 'should get index' do
    get :index
    assert_response :success
  end

  test 'should get show' do
    get :show, material_id: materials(:good_material).id
    assert_response :success
  end

end
