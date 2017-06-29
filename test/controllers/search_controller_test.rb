require 'test_helper'

class SearchControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  setup do
    mock_images
  end

  test 'should get index and event count' do
    begin
      TeSS::Config.solr_enabled = true

      search_method = proc { |model| MockSearch.new(model.limit(3).to_a) }

      Sunspot.blockless_stub(:search, search_method) do
        get :index, q: 'banana'
        assert_response :success
        assert_not_empty assigns(:results)
        get :count_events, :format => 'json', q: 'pomegranate'
        assert_response :success
        assert_not_empty assigns(:results)
      end

    ensure
      TeSS::Config.solr_enabled = false
    end
  end

end
