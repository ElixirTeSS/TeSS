require 'test_helper'

class SearchControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  setup do
    mock_images
  end

  test 'should get index' do
    begin
      TeSS::Config.solr_enabled = true

      search_method = proc {
        return MockSearch.new(SearchController::SEARCH_MODELS.map { |c| c.constantize.limit(3).to_a }.flatten)
      }

      Sunspot.stub(:search, search_method) do
        get :index, q: 'banana'
        assert_response :success
        assert_not_empty assigns(:results)
      end

    ensure
      TeSS::Config.solr_enabled = false
    end
  end
end
