require 'test_helper'

class CommunitiesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get community page' do
    Event.stub(:search_and_filter, MockSearch.new(Event.all)) do
      Material.stub(:search_and_filter, MockSearch.new(Material.all)) do
        get :show, params: { id: 'uk' }
        assert_response :success
        assert_select 'h1', text: /UK training/
      end
    end
  end

  test 'should 404 on bad community id' do
    assert_raises(ActionController::RoutingError) do
      get :show, params: { id: 'banana' }
    end
  end
end
