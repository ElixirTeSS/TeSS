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

  test 'should restrict searches to current space' do
    plant_space = spaces(:plants)
    # Dummy class that records which `with` constraints were used in the search
    dummy_search = Class.new do
      attr_reader :constraints

      def initialize
        @constraints = Hash.new(:unset)
      end

      def clear
        @constraints.clear
      end

      def with(field, value = nil)
        @constraints[field] = value
        self
      end

      def method_missing(*args); self; end
    end

    search = dummy_search.new
    Sunspot.stub(:search, ->(_, &block) { search.instance_eval(&block); MockSearch.new([]) }) do
      # When not in a space, with spaces disabled, space constraint should be unset (show everything)
      with_settings(solr_enabled: true, feature: { spaces: false }) do
        get :index, params: { q: 'banana' }
        assert_response :success
        assert_equal :unset, search.constraints[:space_id]
      end

      search.clear
      # When not in a space, with spaces enabled, space constraint should be nil (show things in default space)
      with_settings(solr_enabled: true, feature: { spaces: true }) do
        get :index, params: { q: 'banana' }
        assert_response :success
        assert_nil search.constraints[:space_id]
      end

      with_host(plant_space.host) do
        search.clear
        # When in a space, with spaces enabled, space constraint should be that space's ID (show things in that space)
        with_settings(solr_enabled: true, feature: { spaces: true }) do
          get :index, params: { q: 'banana' }
          assert_response :success
          assert_equal plant_space.id, search.constraints[:space_id]
        end

        search.clear
        # When in a space, with spaces disabled, space constraint should be unset (show everything)
        with_settings(solr_enabled: true, feature: { spaces: false }) do
          get :index, params: { q: 'banana' }
          assert_response :success
          assert_equal :unset, search.constraints[:space_id]
        end
      end
    end
  end
end
