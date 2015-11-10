require 'test_helper'

class StaticControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  test "should get welcome" do
    get :welcome
    assert_response :success
  end

end
