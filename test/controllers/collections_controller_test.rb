# frozen_string_literal: true

require 'test_helper'

class CollectionsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ActiveJob::TestHelper

  setup do
    mock_images
    @collection = collections(:one)
    @updated_collection = {
      title: 'New title',
      description: 'New description'
    }
  end
  # INDEX TESTS
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:collections)
  end

  test 'should get index as json' do
    get :index, format: :json
    assert_response :success
    assert_not_nil assigns(:collections)
  end

  test 'should get index as json-api' do
    @collection.materials << materials(:good_material)
    @collection.events << events(:one)

    get :index, params: { format: :json_api }
    assert_response :success
    assert_not_nil assigns(:collections)
    assert_valid_json_api_response

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert body['data'].any?
    assert (body['meta']['results-count']).positive?
    assert body['meta'].key?('query')
    assert body['meta'].key?('facets')
    assert body['meta'].key?('available-facets')
    assert_equal collections_path, body['links']['self']
  end

  # NEW TESTS
  test 'should get new' do
    sign_in users(:regular_user)
    get :new
    assert_response :success
  end

  test 'should get new page for logged in users only' do
    # Redirect to login if not logged in
    get :new
    assert_response :redirect
    sign_in users(:regular_user)
    # Success for everyone else
    get :new
    assert_response :success
    sign_in users(:admin)
    get :new
    assert_response :success
  end

  # EDIT TESTS
  test 'should not get edit page for not logged in users' do
    # Not logged in = Redirect to login
    get :edit, params: { id: @collection }
    assert_redirected_to new_user_session_path
  end

  # logged in but insufficient permissions = ERROR
  test 'should get edit for collection owner' do
    sign_in @collection.user
    get :edit, params: { id: @collection }
    assert_response :success
  end

  test 'should get edit for admin' do
    # Owner of collection logged in = SUCCESS
    sign_in users(:admin)
    get :edit, params: { id: @collection }
    assert_response :success
  end

  test 'should not get edit page for non-owner user' do
    # Administrator = SUCCESS
    sign_in users(:another_regular_user)
    get :edit, params: { id: @collection }
    assert :forbidden
  end

  # CURATE TESTS
  test 'should not get curation page for not logged in users' do
    # Not logged in = Redirect to login
    get :curate, params: { id: @collection, type: 'Event' }
    assert_redirected_to new_user_session_path
  end

  test 'should get curate for collection owner' do
    sign_in @collection.user
    get :curate, params: { id: @collection, type: 'Event' }
    assert_response :success
  end

  test 'should get curate for admin' do
    # Owner of collection logged in = SUCCESS
    sign_in users(:admin)
    get :curate, params: { id: @collection, type: 'Event' }
    assert_response :success
  end

  test 'should not get curate page for non-owner user' do
    # Administrator = SUCCESS
    sign_in users(:another_regular_user)
    get :curate, params: { id: @collection, type: 'Event' }
    assert :forbidden
  end

  # CREATE TEST
  test 'should create collection for user' do
    sign_in users(:regular_user)
    assert_difference('Collection.count') do
      post :create, params: { collection: { title: @collection.title, image_url: @collection.image_url, description: @collection.description } }
    end
    assert_redirected_to collection_path(assigns(:collection))
  end

  test 'should create collection for admin' do
    sign_in users(:admin)
    assert_difference('Collection.count') do
      post :create, params: { collection: { title: @collection.title, image_url: @collection.image_url, description: @collection.description } }
    end
    assert_redirected_to collection_path(assigns(:collection))
  end

  test 'should not create collection for non-logged in user' do
    assert_no_difference('Collection.count') do
      post :create, params: { collection: { title: @collection.title, image_url: @collection.image_url, description: @collection.description } }
    end
    assert_redirected_to new_user_session_path
  end

  # SHOW TEST
  test 'should show collection' do
    get :show, params: { id: @collection }
    assert_response :success
    assert assigns(:collection)
  end

  test 'should show collection as json' do
    @collection.materials << materials(:good_material)
    @collection.events << events(:one)

    get :show, params: { id: @collection, format: :json }

    assert_response :success
    assert assigns(:collection)
  end

  test 'should show collection as json-api' do
    @collection.materials << materials(:good_material)
    @collection.events << events(:one)

    get :show, params: { id: @collection, format: :json_api }
    assert_response :success
    assert assigns(:collection)
    assert_valid_json_api_response

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert_equal @collection.title, body['data']['attributes']['title']
    assert_equal collection_path(assigns(:collection)), body['data']['links']['self']
  end

  # UPDATE TEST
  test 'should update collection' do
    sign_in @collection.user
    patch :update, params: { id: @collection, collection: @updated_collection }
    assert_redirected_to collection_path(assigns(:collection))
  end

  test 'should add items to collection' do
    sign_in users(:regular_user)
    collection = collections(:with_resources)
    assert_difference('CollectionItem.count', 3) do
      assert_difference('collection.events.count', 1) do
        assert_difference('collection.materials.count', 2) do
          patch :update, params: { id: collection.id, collection: { items_attributes: {
            '0' => { resource_type: 'Material', resource_id: materials(:biojs).id, order: 2, comment: 'hello' },
            '1' => { resource_type: 'Event', resource_id: events(:one).id, order: 1, comment: 'hello!' },
            '2' => { resource_type: 'Material', resource_id: materials(:interpro).id, order: 1, comment: 'hello!!' }
          } } }

          mats = assigns(:collection).material_items
          assert_equal 2, mats.length
          assert_equal 1, mats[0].order
          assert_equal 'hello!!', mats[0].comment
          assert_equal materials(:interpro), mats[0].resource
          assert_equal 2, mats[1].order
          assert_equal 'hello', mats[1].comment
          assert_equal materials(:biojs), mats[1].resource

          events = assigns(:collection).event_items
          assert_equal 1, events.length
          assert_equal 1, events[0].order
          assert_equal 'hello!', events[0].comment
          assert_equal events(:one), events[0].resource
        end
      end
    end
  end

  test 'should remove items from collection' do
    sign_in users(:regular_user)
    collection = collections(:with_resources)
    ci1 = collection.items.create!(resource: materials(:biojs), order: 2, comment: 'hello')
    ci2 = collection.items.create!(resource: materials(:interpro), order: 1, comment: 'hello!!')
    ci3 = collection.items.create!(resource: events(:one), order: 1, comment: 'hello!')

    assert_difference('CollectionItem.count', -1) do
      assert_difference('collection.materials.count', -1) do
        assert_no_difference('collection.events.count') do
          patch :update, params: { id: collection.id, collection: { items_attributes: {
            '0' => { id: ci1.id, resource_type: 'Material', resource_id: materials(:biojs).id, order: 2, comment: 'hello' },
            '1' => { id: ci3.id, resource_type: 'Event', resource_id: events(:one).id, order: 1, comment: 'hello!' },
            '2' => { id: ci2.id, resource_type: 'Material', resource_id: materials(:interpro).id, order: 1, comment: 'hello!!', _destroy: '1' }
          } } }

          mats = assigns(:collection).material_items
          assert_equal ci1.id, mats[0].id
          assert_equal 1, mats.length
          assert_equal 1, mats[0].order
          assert_equal 'hello', mats[0].comment
          assert_equal materials(:biojs), mats[0].resource

          events = assigns(:collection).event_items
          assert_equal 1, events.length
          assert_equal ci3.id, events[0].id
          assert_equal 1, events[0].order
          assert_equal 'hello!', events[0].comment
          assert_equal events(:one), events[0].resource
        end
      end
    end
  end

  test 'should modify items in collection' do
    sign_in users(:regular_user)
    collection = collections(:with_resources)
    ci1 = collection.items.create!(resource: materials(:biojs), order: 2, comment: 'hello')
    ci2 = collection.items.create!(resource: materials(:interpro), order: 1, comment: 'hello!!')
    ci3 = collection.items.create!(resource: events(:one), order: 1, comment: 'hello!')

    assert_no_difference('CollectionItem.count') do
      assert_no_difference('collection.materials.count') do
        assert_no_difference('collection.events.count') do
          patch :update, params: { id: collection.id, collection: { items_attributes: {
            '0' => { id: ci1.id, resource_type: 'Material', resource_id: materials(:biojs).id, order: 1, comment: 'hello world' },
            '1' => { id: ci3.id, resource_type: 'Event', resource_id: events(:one).id, order: 1, comment: 'hello world!' },
            '2' => { id: ci2.id, resource_type: 'Material', resource_id: materials(:interpro).id, order: 2, comment: 'hello world!!' }
          } } }

          mats = assigns(:collection).material_items
          assert_equal 2, mats.length
          assert_equal ci1.id, mats[0].id
          assert_equal 1, mats[0].order
          assert_equal 'hello world', mats[0].comment
          assert_equal materials(:biojs), mats[0].resource
          assert_equal ci2.id, mats[1].id
          assert_equal 2, mats[1].order
          assert_equal 'hello world!!', mats[1].comment
          assert_equal materials(:interpro), mats[1].resource

          events = assigns(:collection).event_items
          assert_equal 1, events.length
          assert_equal ci3.id, events[0].id
          assert_equal 1, events[0].order
          assert_equal 'hello world!', events[0].comment
          assert_equal events(:one), events[0].resource
        end
      end
    end
  end

  # UPDATE_CURATE TEST
  test 'should add and remove elements' do
    sign_in @collection.user
    @collection.events << events(:one)
    assert_equal [events(:one).id], @collection.reload.event_ids

    patch :update_curation, params: {
      type: 'Event',
      id: @collection,
      reviewed_item_ids: [events(:one).id, events(:two).id],
      item_ids: [events(:two).id]
    }

    assert_equal [events(:two).id], @collection.reload.event_ids
    assert_redirected_to collection_path(assigns(:collection))
  end

  test 'should not create double CollectionItems' do
    sign_in @collection.user
    @collection.events << events(:one)
    assert_equal [events(:one).id], @collection.reload.event_ids

    patch :update_curation, params: {
      type: 'Event',
      id: @collection,
      reviewed_item_ids: [events(:one).id, events(:two).id],
      item_ids: [events(:one).id]
    }

    assert_equal [events(:one).id], @collection.reload.event_ids
    assert_equal 1, @collection.items.count
    assert_redirected_to collection_path(assigns(:collection))
  end

  # DESTROY TEST
  test 'should destroy collection owned by user' do
    sign_in @collection.user
    assert_difference('Collection.count', -1) do
      delete :destroy, params: { id: @collection }
    end
    assert_redirected_to collections_path
  end

  test 'should destroy collection when administrator' do
    sign_in users(:admin)
    assert_difference('Collection.count', -1) do
      delete :destroy, params: { id: @collection }
    end
    assert_redirected_to collections_path
  end

  test 'should not destroy collection not owned by user' do
    sign_in users(:another_regular_user)
    assert_no_difference('Collection.count') do
      delete :destroy, params: { id: @collection }
    end
    assert_response :forbidden
  end

  # CONTENT TESTS
  # BREADCRUMBS
  test 'breadcrumbs for collections index' do
    get :index
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li[class=active]', text: /Collections/, count: 1
    end
  end

  test 'breadcrumbs for showing collection' do
    get :show, params: { id: @collection }
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li', text: /Collections/, count: 1 do
        assert_select 'a[href=?]', collections_url, count: 1
      end
      assert_select 'li[class=active]', text: /#{@collection.title}/, count: 1
    end
  end

  test 'breadcrumbs for editing collection' do
    sign_in users(:admin)
    get :edit, params: { id: @collection }
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li', text: /Collections/, count: 1 do
        assert_select 'a[href=?]', collections_url, count: 1
      end
      assert_select 'li', text: /#{@collection.title}/, count: 1 do
        assert_select 'a[href=?]', collection_url(@collection), count: 1
      end
      assert_select 'li[class=active]', text: /Edit/, count: 1
    end
  end

  test 'breadcrumbs for creating new collection' do
    sign_in users(:regular_user)
    get :new
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li', text: /Collections/, count: 1 do
        assert_select 'a[href=?]', collections_url, count: 1
      end
      assert_select 'li[class=active]', text: /New/, count: 1
    end
  end

  # OTHER CONTENT
  test 'collection has correct tabs' do
    get :show, params: { id: @collection }
    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li.disabled', count: 2 # This collection has no events, materials
    end

    collections(:with_resources).materials << materials(:good_material)
    collections(:with_resources).events << events(:one)

    get :show, params: { id: collections(:with_resources) }
    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li' do
        assert_select 'a[data-toggle="tab"]', count: 2 # Events, Materials
      end
    end
  end

  test 'collection has correct layout' do
    get :show, params: { id: @collection }
    assert_response :success
    assert_select 'div.search-results-count', count: 2 # Has results
    # assert_select 'a.btn-info', :text => 'Back', :count => 1 #No Edit
    # Should not show when not logged in
    assert_select 'a.btn[href=?]', edit_collection_path(@collection), count: 0 # No Edit
    assert_select 'a.btn[href=?]', collection_path(@collection), count: 0 # No Edit
  end

  test 'do not show action buttons when not owner or admin' do
    sign_in users(:another_regular_user)
    get :show, params: { id: @collection }
    assert_select 'a.btn[href=?]', edit_collection_path(@collection), count: 0 # No Edit
    assert_select 'a.btn[href=?]', collection_path(@collection), count: 0 # No Edit
  end

  test 'show action buttons when owner' do
    sign_in @collection.user
    get :show, params: { id: @collection }
    assert_select 'a.btn[href=?]', edit_collection_path(@collection), count: 1
    assert_select 'a.btn[href=?]', collection_path(@collection), text: 'Delete', count: 1
  end

  test 'show action buttons when admin' do
    sign_in users(:admin)
    get :show, params: { id: @collection }
    assert_select 'a.btn[href=?]', edit_collection_path(@collection), count: 1
    assert_select 'a.btn[href=?]', collection_path(@collection), text: 'Delete', count: 1
  end

  # API Actions
  test 'should add materials to collection' do
    sign_in users(:regular_user)
    collection = collections(:with_resources)
    assert_difference('CollectionItem.count', 2) do
      assert_difference('collection.materials.count', 2) do
        patch :update, params: { collection: { material_ids: [materials(:biojs), materials(:interpro)] }, id: collection.id }
      end
    end
  end

  test 'should remove materials from collection' do
    sign_in users(:regular_user)
    collection = collections(:with_resources)
    collection.materials = [materials(:biojs), materials(:interpro)]
    collection.save!
    assert_difference('CollectionItem.count', -2) do
      assert_difference('collection.materials.count', -2) do
        patch :update, params: { collection: { material_ids: [''] }, id: collection.id }
      end
    end
  end

  test 'should add events to collection' do
    sign_in users(:regular_user)
    assert_difference('CollectionItem.count', 2) do
      assert_difference('@collection.events.count', 2) do
        patch :update, params: { collection: { event_ids: [events(:one), events(:two)] }, id: @collection.id }
      end
    end
  end

  test 'should remove events from collection' do
    sign_in users(:regular_user)
    collection = collections(:with_resources)
    collection.events = [events(:one), events(:two)]
    collection.save!
    assert_difference('CollectionItem.count', -2) do
      assert_difference('collection.events.count', -2) do
        patch :update, params: { collection: { event_ids: [''] }, id: collection.id }
      end
    end
  end

  test 'should not allow access to private collections' do
    get :show, params: { id: collections(:secret_collection) }
    assert_response :forbidden
  end

  test 'should allow access to private collections if privileged' do
    sign_in users(:regular_user)
    get :show, params: { id: collections(:secret_collection) }
    assert_response :success
  end

  test 'should hide private collections from index' do
    get :index
    assert_response :success
    assert_not_includes assigns(:collections).map(&:id), collections(:secret_collection).id
  end

  test 'should not hide private collections from index from collection owner' do
    sign_in users(:regular_user)
    get :index
    assert_response :success
    assert_includes assigns(:collections).map(&:id), collections(:secret_collection).id
  end

  test 'should not hide private collections from index from admin' do
    sign_in users(:admin)
    get :index
    assert_response :success
    assert_includes assigns(:collections).map(&:id), collections(:secret_collection).id
  end

  test 'should log changes when updating a collection' do
    sign_in @collection.user
    assert @collection.save
    @collection.activities.destroy_all

    # 3 = 2 for parameters + 1 for update
    assert_difference('PublicActivity::Activity.count', 3) do
      patch :update, params: { id: @collection, collection: @updated_collection }
    end

    assert_equal 1, @collection.activities.where(key: 'collection.update').count
    assert_equal 2, @collection.activities.where(key: 'collection.update_parameter').count

    parameters = @collection.activities.where(key: 'collection.update_parameter').map(&:parameters)
    title_activity = parameters.detect { |p| p[:attr] == 'title' }
    description_activity = parameters.detect { |p| p[:attr] == 'description' }

    assert_equal 'New title', title_activity[:new_val]
    assert_equal 'New description', description_activity[:new_val]

    old_controller = @controller
    @controller = ActivitiesController.new

    get :index, params: { collection_id: @collection }, xhr: true

    assert_select '.activity', count: 4 # +1 because they are wrapped in a .activity div for some reason...

    @controller = old_controller
  end

  test 'should trigger notification when unverified user creates collection' do
    sign_in users(:unverified_user)

    assert_enqueued_jobs 1 do
      assert_difference('Collection.count') do
        post :create, params: { collection: { title: 'Second collection' } }
      end
    end

    assert_redirected_to collection_path(assigns(:collection))
    @collection.reload
  end

  test 'should not trigger notification if unverified user already created content' do
    sign_in users(:unverified_user)
    users(:unverified_user).collections.create!(title: 'First collection')

    assert_enqueued_jobs 0 do
      assert_difference('Collection.count') do
        post :create, params: { collection: { title: 'Second collection' } }
      end
    end

    assert_redirected_to collection_path(assigns(:collection))
    @collection.reload
  end

  test 'should allow collaborator to edit' do
    user = users(:another_regular_user)
    @collection.collaborators << user
    sign_in user

    assert_difference('CollectionItem.count', 2) do
      patch :update, params: { collection: { event_ids: [events(:one), events(:two)] }, id: @collection.id }
    end
    assert_redirected_to collection_path(assigns(:collection))
  end

  test 'should not allow non-collaborator to edit' do
    user = users(:another_regular_user)
    sign_in user

    assert_no_difference('CollectionItem.count') do
      patch :update, params: { collection: { event_ids: [events(:one), events(:two)] }, id: @collection.id }
    end
    assert_response :forbidden
  end

  test 'should render collection items in order' do
    materials = [materials(:good_material), materials(:biojs), materials(:interpro)]
    events = [events(:two), events(:one)]
    @collection.items.create!(resource: materials[0], order: 2, comment: 'A good material')
    @collection.items.create!(resource: materials[1], order: 1, comment: 'Start here')
    @collection.items.create!(resource: materials[2], order: 3, comment: 'End here')
    @collection.items.create!(resource: events[0], order: 2, comment: 'End here')
    @collection.items.create!(resource: events[1], order: 1, comment: 'Start here')

    get :show, params: { id: @collection }

    assert_response :success

    assert_select '#materials ul li:nth-child(1) .link-overlay' do
      assert_select 'h4', text: 'BioJS'
      assert_select '.collection-item-comment', text: 'Start here'
      assert_select '.collection-item-order-badge', text: '1'
    end

    assert_select '#materials ul li:nth-child(2) .link-overlay' do
      assert_select 'h4', text: 'Training Material Example'
      assert_select '.collection-item-comment', text: 'A good material'
      assert_select '.collection-item-order-badge', text: '2'
    end

    assert_select '#materials ul li:nth-child(3) .link-overlay' do
      assert_select 'h4', text: 'InterPro'
      assert_select '.collection-item-comment', text: 'End here'
      assert_select '.collection-item-order-badge', text: '3'
    end

    assert_select '#events ul li:nth-child(1) .link-overlay' do
      assert_select 'h4', text: 'event one'
      assert_select '.collection-item-comment', text: 'Start here'
      assert_select '.collection-item-order-badge', text: '1'
    end

    assert_select '#events ul li:nth-child(2) .link-overlay' do
      assert_select 'h4', text: 'event two'
      assert_select '.collection-item-comment', text: 'End here'
      assert_select '.collection-item-order-badge', text: '2'
    end
  end

  test 'should render collection items in order as json-api' do
    materials = [materials(:good_material), materials(:biojs), materials(:interpro)]
    events = [events(:two), events(:one)]
    @collection.items.create!(resource: materials[0], order: 2, comment: 'A good material')
    @collection.items.create!(resource: materials[1], order: 1, comment: 'Start here')
    @collection.items.create!(resource: materials[2], order: 3, comment: 'End here')
    @collection.items.create!(resource: events[0], order: 2, comment: 'End here')
    @collection.items.create!(resource: events[1], order: 1, comment: 'Start here')

    get :show, params: { id: @collection, format: :json_api }

    assert_response :success
    assert assigns(:collection)
    assert_valid_json_api_response

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    response_materials = body.dig('data', 'relationships', 'materials', 'data')
    assert_equal([materials[1].id, materials[0].id, materials[2].id], response_materials.map { |m| m['id'].to_i })

    response_events = body.dig('data', 'relationships', 'events', 'data')
    assert_equal([events[1].id, events[0].id], response_events.map { |e| e['id'].to_i })
  end
end
