require 'test_helper'

class SearchControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  setup do
    mock_images
  end

  test "should get index" do
    get :index
    assert_response :success
  end
end
