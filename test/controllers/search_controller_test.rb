require 'test_helper'

class SearchControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  setup do
    mock_images
  end

  test 'should get index' do
    with_settings(solr_enabled: true) do
      search_method = proc { |model| MockSearch.new(model.limit(3).to_a) }

      Sunspot.blockless_stub(:search, search_method) do
        get :index, params: { q: 'banana' }
        assert_response :success
        assert_not_empty assigns(:results)
      end
    end
  end

end
