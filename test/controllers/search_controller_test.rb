require 'test_helper'

class SearchControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  setup do
    #
  end

  test "should get index" do
    get :index
    assert_response :success
  end
end
