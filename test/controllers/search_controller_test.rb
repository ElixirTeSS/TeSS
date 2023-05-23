# frozen_string_literal: true

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

        assert_select '#main-container ul.nav' do
          assert_select 'li:nth-child(1).active a[href=?]', '#events'
          assert_select 'li:nth-child(2) a[href=?]', '#materials'
          assert_select 'li:nth-child(3) a[href=?]', '#collections'
        end
      end
    end
  end

  test 'search result tabs should respect configured tab order' do
    with_settings(solr_enabled: true,
                  site: { tab_order: ['content_providers', 'materials', 'collections', 'events'] }) do
      search_method = proc { |model| MockSearch.new(model.limit(3).to_a) }

      Sunspot.blockless_stub(:search, search_method) do
        get :index, params: { q: 'banana' }
        assert_response :success
        assert_not_empty assigns(:results)

        assert_select '#main-container ul.nav' do
          assert_select 'li:nth-child(1).active a[href=?]', '#content_providers'
          assert_select 'li:nth-child(2) a[href=?]', '#materials'
          assert_select 'li:nth-child(3) a[href=?]', '#collections'
          assert_select 'li:nth-child(4) a[href=?]', '#events'
        end
      end
    end
  end
end
