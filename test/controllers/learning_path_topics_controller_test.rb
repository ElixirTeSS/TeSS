require 'test_helper'

class LearningPathTopicsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ActiveJob::TestHelper

  setup do
    mock_images
    @learning_path_topic = learning_path_topics(:good_and_bad)
    @updated_learning_path_topic = {
      title: 'New title',
      description: 'New description'
    }
  end
  #INDEX TESTS
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:learning_path_topics)
  end

  test 'should get index as json' do
    skip 'JSON not yet implemented'
    get :index, format: :json
    assert_response :success
    assert_not_nil assigns(:learning_path_topics)
  end

  test 'should get index as json-api' do
    skip 'JSON not yet implemented'
    get :index, params: { format: :json_api }
    assert_response :success
    assert_not_nil assigns(:learning_path_topics)
    assert_valid_json_api_response

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert body['data'].any?
    assert body['meta']['results-count'] > 0
    assert body['meta'].key?('query')
    assert body['meta'].key?('facets')
    assert body['meta'].key?('available-facets')
    assert_equal learning_path_topics_path, body['links']['self']
  end


  #NEW TESTS

  test 'should get new page for curators and admins only' do
    get :new
    assert_response :redirect

    sign_in users(:regular_user)
    get :new
    assert_response :forbidden

    sign_in users(:curator)
    get :new
    assert_response :success

    sign_in users(:admin)
    get :new
    assert_response :success
  end

  #EDIT TESTS
  test 'should not get edit page for not logged in users' do
    #Not logged in = Redirect to login
    get :edit, params: { id: @learning_path_topic }
    assert_redirected_to new_user_session_path
  end

  #logged in but insufficient permissions = ERROR
  test 'should get edit for learning_path_topic owner' do
    sign_in @learning_path_topic.user
    get :edit, params: { id: @learning_path_topic }
    assert_response :success
  end

  test 'should get edit for admin' do
    #Owner of learning_path_topic logged in = SUCCESS
    sign_in users(:admin)
    get :edit, params: { id: @learning_path_topic }
    assert_response :success
  end

  test 'should not get edit page for regular user' do
    #Administrator = SUCCESS
    sign_in users(:another_regular_user)
    get :edit, params: { id: @learning_path_topic }
    assert :forbidden
  end

  #CREATE TEST
  test 'should create learning_path_topic for curator' do
    sign_in users(:curator)
    assert_difference('LearningPathTopic.count') do
      post :create, params: { learning_path_topic: { title: @learning_path_topic.title, description: @learning_path_topic.description } }
    end
    assert_redirected_to learning_path_topic_path(assigns(:learning_path_topic))
  end

  test 'should create learning_path_topic for admin' do
    sign_in users(:admin)
    assert_difference('LearningPathTopic.count') do
      post :create, params: { learning_path_topic: { title: @learning_path_topic.title, description: @learning_path_topic.description } }
    end
    assert_redirected_to learning_path_topic_path(assigns(:learning_path_topic))
  end

  test 'should not create learning_path_topic for regular user' do
    sign_in users(:regular_user)
    assert_no_difference('LearningPathTopic.count') do
      post :create, params: { learning_path_topic: { title: @learning_path_topic.title, description: @learning_path_topic.description } }
    end
    assert_response :forbidden
  end

  test 'should not create learning_path_topic for non-logged in user' do
    assert_no_difference('LearningPathTopic.count') do
      post :create, params: { learning_path_topic: { title: @learning_path_topic.title, description: @learning_path_topic.description } }
    end
    assert_redirected_to new_user_session_path
  end

  #SHOW TEST
  test 'should show learning_path_topic' do
    get :show, params: { id: @learning_path_topic }
    assert_response :success
    assert assigns(:learning_path_topic)
  end

  test 'should show learning_path_topic as json' do
    skip 'JSON not yet implemented'
    get :show, params: { id: @learning_path_topic, format: :json }

    assert_response :success
    assert assigns(:learning_path_topic)
  end

  test 'should show learning_path_topic as json-api' do
    skip 'JSON not yet implemented'
    get :show, params: { id: @learning_path_topic, format: :json_api }
    assert_response :success
    assert assigns(:learning_path_topic)
    assert_valid_json_api_response

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert_equal @learning_path_topic.title, body['data']['attributes']['title']
    assert_equal learning_path_topic_path(assigns(:learning_path_topic)), body['data']['links']['self']
  end

  #UPDATE TEST
  test 'should update learning_path_topic' do
    sign_in @learning_path_topic.user
    patch :update, params: { id: @learning_path_topic, learning_path_topic: @updated_learning_path_topic }
    assert_redirected_to learning_path_topic_path(assigns(:learning_path_topic))
  end

  test "should add items to learning_path_topic" do
    sign_in users(:curator)
    learning_path_topic = learning_path_topics(:good_and_bad)

    ci1, ci2 = learning_path_topic.items

    assert_difference('LearningPathTopicItem.count', 1) do
      assert_difference('learning_path_topic.materials.count', 1) do
        assert_no_difference('learning_path_topic.events.count') do
          patch :update, params: { id: learning_path_topic.id, learning_path_topic: { items_attributes: {
            '1': { id: ci1.id, resource_type: 'Material', resource_id: materials(:bad_material).id, order: 1 },
            '2': { resource_type: 'Material', resource_id: materials(:prints).id, order: 3, comment: 'hello world!' },
            '3': { id: ci2.id, resource_type: 'Material', resource_id: materials(:good_material).id, order: 2, comment: 'Some explanation' }
          } } }

          assert_redirected_to learning_path_topic

          mats = assigns(:learning_path_topic).material_items

          assert_equal 3, mats.length
          assert_equal ci1.id, mats[0].id
          assert_equal 1, mats[0].order
          assert_nil mats[0].comment
          assert_equal materials(:bad_material), mats[0].resource
          assert_equal ci2.id, mats[1].id
          assert_equal 2, mats[1].order
          assert_equal 'Some explanation', mats[1].comment
          assert_equal materials(:good_material), mats[1].resource
          assert_not_nil mats[2].id
          assert_equal 3, mats[2].order
          assert_equal 'hello world!', mats[2].comment
          assert_equal materials(:prints), mats[2].resource
        end
      end
    end
  end

  test "should remove items from learning_path_topic" do
    sign_in users(:curator)
    learning_path_topic = learning_path_topics(:goblet_things)

    ci1, ci2, ci3 = learning_path_topic.items

    assert_difference('LearningPathTopicItem.count', -1) do
      assert_difference('learning_path_topic.materials.count', -1) do
        assert_no_difference('learning_path_topic.events.count') do
          patch :update, params: { id: learning_path_topic.id, learning_path_topic: { items_attributes: {
            '1': { id: ci1.id, resource_type: 'Material', resource_id: materials(:biojs).id, order: 1, comment: 'hello world' },
            '2': { id: ci3.id, resource_type: 'Material', resource_id: materials(:prints).id, order: 3, comment: 'hello world!' },
            '3': { id: ci2.id, resource_type: 'Material', resource_id: materials(:interpro).id, order: 2, comment: 'hello world!!', _destroy: '1' }
          } } }

          assert_redirected_to learning_path_topic

          mats = assigns(:learning_path_topic).material_items

          assert_equal 2, mats.length
          assert_equal ci1.id, mats[0].id
          assert_equal 1, mats[0].order
          assert_equal 'hello world', mats[0].comment
          assert_equal materials(:biojs), mats[0].resource
          assert_equal ci3.id, mats[1].id
          assert_equal 2, mats[1].order
          assert_equal 'hello world!', mats[1].comment
          assert_equal materials(:prints), mats[1].resource
        end
      end
    end
  end

  test "should modify items in learning_path_topic" do
    sign_in users(:curator)
    learning_path_topic = learning_path_topics(:goblet_things)

    ci1, ci2, ci3 = learning_path_topic.items

    assert_no_difference('LearningPathTopicItem.count') do
      assert_no_difference('learning_path_topic.materials.count') do
        assert_no_difference('learning_path_topic.events.count') do
          patch :update, params: { id: learning_path_topic.id, learning_path_topic: { items_attributes: {
            '1': { id: ci1.id, resource_type: 'Material', resource_id: materials(:biojs).id, order: 1, comment: 'hello world' },
            '2': { id: ci3.id, resource_type: 'Material', resource_id: materials(:prints).id, order: 3, comment: 'hello world!' },
            '3': { id: ci2.id, resource_type: 'Material', resource_id: materials(:interpro).id, order: 2, comment: 'hello world!!' }
          } } }

          assert_redirected_to learning_path_topic

          mats = assigns(:learning_path_topic).material_items

          assert_equal 3, mats.length
          assert_equal ci1.id, mats[0].id
          assert_equal 1, mats[0].order
          assert_equal 'hello world', mats[0].comment
          assert_equal materials(:biojs), mats[0].resource
          assert_equal ci2.id, mats[1].id
          assert_equal 2, mats[1].order
          assert_equal 'hello world!!', mats[1].comment
          assert_equal materials(:interpro), mats[1].resource
          assert_equal ci3.id, mats[2].id
          assert_equal 3, mats[2].order
          assert_equal 'hello world!', mats[2].comment
          assert_equal materials(:prints), mats[2].resource
        end
      end
    end
  end

  #DESTROY TEST
  test 'should destroy learning_path_topic owned by user' do
    sign_in @learning_path_topic.user
    assert_difference('LearningPathTopic.count', -1) do
      delete :destroy, params: { id: @learning_path_topic }
    end
    assert_redirected_to learning_path_topics_path
  end

  test 'should destroy learning_path_topic when administrator' do
    sign_in users(:admin)
    assert_difference('LearningPathTopic.count', -1) do
      delete :destroy, params: { id: @learning_path_topic }
    end
    assert_redirected_to learning_path_topics_path
  end

  test 'should not destroy learning_path_topic not owned by user' do
    sign_in users(:another_regular_user)
    assert_no_difference('LearningPathTopic.count') do
      delete :destroy, params: { id: @learning_path_topic }
    end
    assert_response :forbidden
  end


  #CONTENT TESTS
  #BREADCRUMBS
  test 'breadcrumbs for learning_path_topics index' do
    get :index
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li[class=active]', text: /Topics/, count: 1
    end
  end

  test 'breadcrumbs for showing learning_path_topic' do
    get :show, params: { id: @learning_path_topic }
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li', text: /Topics/, count: 1 do
        assert_select 'a[href=?]', learning_path_topics_url, count: 1
      end
      assert_select 'li[class=active]', text: /#{@learning_path_topic.title}/, count: 1
    end
  end

  test 'breadcrumbs for editing learning_path_topic' do
    sign_in users(:admin)
    get :edit, params: { id: @learning_path_topic }
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li', text: /Topics/, count: 1 do
        assert_select 'a[href=?]', learning_path_topics_url, count: 1
      end
      assert_select 'li', text: /#{@learning_path_topic.title}/, count: 1 do
        assert_select 'a[href=?]', learning_path_topic_url(@learning_path_topic), count: 1
      end
      assert_select 'li[class=active]', text: /Edit/, count: 1
    end
  end

  test 'breadcrumbs for creating new learning_path_topic' do
    sign_in users(:curator)
    get :new
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li', text: /Topics/, count: 1 do
        assert_select 'a[href=?]', learning_path_topics_url, count: 1
      end
      assert_select 'li[class=active]', text: /New/, count: 1
    end
  end

  #OTHER CONTENT
  test 'learning_path_topic has correct tabs' do
    topic = learning_path_topics(:empty_topic)
    get :show, params: { id: topic }
    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li.disabled', count: 1 # Only materials are currently shown for topics
    end

    topic.materials << materials(:good_material)
    topic.events << events(:one)

    get :show, params: { id: topic }
    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li' do
        assert_select 'a[data-toggle="tab"]', count: 1 # Only materials are currently shown for topics
      end
    end
  end

  test 'learning_path_topic has correct layout' do
    get :show, params: { id: @learning_path_topic }
    assert_response :success
    assert_select 'div.search-results-count', count: 2 #Has results
    assert_select 'a.btn[href=?]', edit_learning_path_topic_path(@learning_path_topic), count: 0 #No Edit
    assert_select 'a.btn[href=?]', learning_path_topic_path(@learning_path_topic), count: 0 #No Edit

  end

  test 'do not show action buttons when not owner or admin' do
    sign_in users(:another_regular_user)
    get :show, params: { id: @learning_path_topic }
    assert_select 'a.btn[href=?]', edit_learning_path_topic_path(@learning_path_topic), count: 0 #No Edit
    assert_select 'a.btn[href=?]', learning_path_topic_path(@learning_path_topic), count: 0 #No Edit
  end

  test 'show action buttons when owner' do
    sign_in @learning_path_topic.user
    get :show, params: { id: @learning_path_topic }
    assert_select 'a.btn[href=?]', edit_learning_path_topic_path(@learning_path_topic), count: 1
    assert_select 'a.btn[href=?]', learning_path_topic_path(@learning_path_topic), text: 'Delete', count: 1
  end

  test 'show action buttons when admin' do
    sign_in users(:admin)
    get :show, params: { id: @learning_path_topic }
    assert_select 'a.btn[href=?]', edit_learning_path_topic_path(@learning_path_topic), count: 1
    assert_select 'a.btn[href=?]', learning_path_topic_path(@learning_path_topic), text: 'Delete', count: 1
  end

  #API Actions
  test "should add materials to learning_path_topic" do
    sign_in users(:admin)
    learning_path_topic = learning_path_topics(:empty_topic)
    assert_difference('LearningPathTopicItem.count', 2) do
      assert_difference('learning_path_topic.materials.count', 2) do
        patch :update, params: { learning_path_topic: { material_ids: [materials(:biojs), materials(:interpro)] }, id: learning_path_topic.id }
      end
    end
  end

  test "should remove materials from learning_path_topic" do
    sign_in users(:curator)
    learning_path_topic = learning_path_topics(:goblet_things)
    assert_difference('LearningPathTopicItem.count', -3) do
      assert_difference('learning_path_topic.materials.count', -3) do
        patch :update, params: { learning_path_topic: { material_ids: [''] }, id: learning_path_topic.id }
      end
    end
  end

  test "should add events to learning_path_topic" do
    sign_in users(:curator)
    assert_difference('LearningPathTopicItem.count', 2) do
      assert_difference('@learning_path_topic.events.count', 2) do
        patch :update, params: { learning_path_topic: { event_ids: [events(:one), events(:two)]}, id: @learning_path_topic.id }
      end
    end
  end

  test "should remove events from learning_path_topic" do
    sign_in users(:admin)
    learning_path_topic = learning_path_topics(:empty_topic)
    learning_path_topic.events = [events(:one), events(:two)]
    learning_path_topic.save!
    assert_difference('LearningPathTopicItem.count', -2) do
      assert_difference('learning_path_topic.events.count', -2) do
        patch :update, params: { learning_path_topic: { event_ids: ['']}, id: learning_path_topic.id }
      end
    end
  end

  test 'should log changes when updating a learning_path_topic' do
    sign_in @learning_path_topic.user
    assert @learning_path_topic.save
    @learning_path_topic.activities.destroy_all

    # 3 = 2 for parameters + 1 for update
    assert_difference('PublicActivity::Activity.count', 3) do
      patch :update, params: { id: @learning_path_topic, learning_path_topic: @updated_learning_path_topic }
    end

    assert_equal 1, @learning_path_topic.activities.where(key: 'learning_path_topic.update').count
    assert_equal 2, @learning_path_topic.activities.where(key: 'learning_path_topic.update_parameter').count

    parameters = @learning_path_topic.activities.where(key: 'learning_path_topic.update_parameter').map(&:parameters)
    title_activity = parameters.detect { |p| p[:attr] == 'title' }
    description_activity = parameters.detect { |p| p[:attr] == 'description' }

    assert_equal 'New title', title_activity[:new_val]
    assert_equal 'New description', description_activity[:new_val]

    old_controller = @controller
    @controller = ActivitiesController.new

    get :index, params: { learning_path_topic_id: @learning_path_topic }, xhr: true

    assert_select '.activity', count: 4 # +1 because they are wrapped in a .activity div for some reason...

    @controller = old_controller
  end

  test 'should allow collaborator to edit' do
    user = users(:another_regular_user)
    @learning_path_topic.collaborators << user
    sign_in user

    assert_difference('LearningPathTopicItem.count', 2) do
      patch :update, params: { learning_path_topic: { event_ids: [events(:one), events(:two)]}, id: @learning_path_topic.id }
    end
    assert_redirected_to learning_path_topic_path(assigns(:learning_path_topic))
  end

  test 'should not allow non-collaborator to edit' do
    user = users(:another_regular_user)
    sign_in user

    assert_no_difference('LearningPathTopicItem.count') do
      patch :update, params: { learning_path_topic: { event_ids: [events(:one), events(:two)]}, id: @learning_path_topic.id }
    end
    assert_response :forbidden
  end

  test 'should render learning_path_topic items in order' do
    events = [events(:two), events(:one)]
    @learning_path_topic.items.create!(resource: events[0], order: 2, comment: 'End here')
    @learning_path_topic.items.create!(resource: events[1], order: 1, comment: 'Start here')

    get :show, params: { id: @learning_path_topic }

    assert_response :success

    assert_select '#materials ul li:nth-child(1) .link-overlay' do
      assert_select 'h4', text: 'Bad Training Material Example'
      assert_select '.collection-item-comment', count: 0
      assert_select '.collection-item-order-badge', text: '1'
    end

    assert_select '#materials ul li:nth-child(2) .link-overlay' do
      assert_select 'h4', text: 'Training Material Example'
      assert_select '.collection-item-comment', text: 'Some explanation'
      assert_select '.collection-item-order-badge', text: '2'
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

  test 'should render learning_path_topic items in order as json-api' do
    skip 'JSON not yet implemented'
    materials = [materials(:good_material), materials(:biojs), materials(:interpro)]
    events = [events(:two), events(:one)]
    @learning_path_topic.items.create!(resource: materials[0], order: 2, comment: 'A good material')
    @learning_path_topic.items.create!(resource: materials[1], order: 1, comment: 'Start here')
    @learning_path_topic.items.create!(resource: materials[2], order: 3, comment: 'End here')
    @learning_path_topic.items.create!(resource: events[0], order: 2, comment: 'End here')
    @learning_path_topic.items.create!(resource: events[1], order: 1, comment: 'Start here')

    get :show, params: { id: @learning_path_topic, format: :json_api }

    assert_response :success
    assert assigns(:learning_path_topic)
    assert_valid_json_api_response

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    response_materials = body.dig('data', 'relationships', 'materials', 'data')
    assert_equal [materials[1].id, materials[0].id, materials[2].id], response_materials.map { |m| m['id'].to_i }

    response_events = body.dig('data', 'relationships', 'events', 'data')
    assert_equal [events[1].id, events[0].id], response_events.map { |e| e['id'].to_i }
  end
end
