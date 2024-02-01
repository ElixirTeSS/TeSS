require 'test_helper'

class LearningPathsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ActiveJob::TestHelper

  setup do
    mock_images
    @learning_path = learning_paths(:one)
    @updated_learning_path = {
      title: 'New title',
      description: 'New description'
    }
  end
  #INDEX TESTS
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:learning_paths)
  end

  test 'should get index as json' do
    skip 'JSON not yet implemented'
    get :index, format: :json
    assert_response :success
    assert_not_nil assigns(:learning_paths)
  end

  test 'should get index as json-api' do
    skip 'JSON not yet implemented'
    @learning_path.materials << materials(:good_material)
    @learning_path.events << events(:one)

    get :index, params: { format: :json_api }
    assert_response :success
    assert_not_nil assigns(:learning_paths)
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
    assert_equal learning_paths_path, body['links']['self']
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
    get :edit, params: { id: @learning_path }
    assert_redirected_to new_user_session_path
  end

  #logged in but insufficient permissions = ERROR
  test 'should get edit for learning_path owner' do
    sign_in @learning_path.user
    get :edit, params: { id: @learning_path }
    assert_response :success
  end

  test 'should get edit for admin' do
    #Owner of learning_path logged in = SUCCESS
    sign_in users(:admin)
    get :edit, params: { id: @learning_path }
    assert_response :success
  end

  test 'should not get edit page for non-owner user' do
    #Administrator = SUCCESS
    sign_in users(:another_regular_user)
    get :edit, params: { id: @learning_path }
    assert :forbidden
  end

  #CREATE TEST
  test 'should create learning_path for curator' do
    sign_in users(:curator)
    assert_difference('LearningPath.count') do
      post :create, params: { learning_path: { title: @learning_path.title, description: @learning_path.description } }
    end
    assert_redirected_to learning_path_path(assigns(:learning_path))
  end

  test 'should create learning_path for admin' do
    sign_in users(:admin)
    assert_difference('LearningPath.count') do
      post :create, params: { learning_path: { title: @learning_path.title, description: @learning_path.description } }
    end
    assert_redirected_to learning_path_path(assigns(:learning_path))
  end

  test 'should not create learning_path for regular user' do
    sign_in users(:regular_user)
    assert_no_difference('LearningPath.count') do
      post :create, params: { learning_path: { title: @learning_path.title, description: @learning_path.description } }
    end
    assert_response :forbidden
  end

  test 'should not create learning_path for non-logged in user' do
    assert_no_difference('LearningPath.count') do
      post :create, params: { learning_path: { title: @learning_path.title, description: @learning_path.description } }
    end
    assert_redirected_to new_user_session_path
  end

  #SHOW TEST
  test 'should show learning_path' do
    get :show, params: { id: @learning_path }
    assert_response :success
    assert assigns(:learning_path)
  end

  test 'should show learning_path as json' do
    skip 'JSON not yet implemented'
    @learning_path.materials << materials(:good_material)
    @learning_path.events << events(:one)

    get :show, params: { id: @learning_path, format: :json }

    assert_response :success
    assert assigns(:learning_path)
  end

  test 'should show learning_path as json-api' do
    skip 'JSON not yet implemented'
    @learning_path.materials << materials(:good_material)
    @learning_path.events << events(:one)

    get :show, params: { id: @learning_path, format: :json_api }
    assert_response :success
    assert assigns(:learning_path)
    assert_valid_json_api_response

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert_equal @learning_path.title, body['data']['attributes']['title']
    assert_equal learning_path_path(assigns(:learning_path)), body['data']['links']['self']
  end

  #UPDATE TEST
  test 'should update learning_path' do
    sign_in @learning_path.user
    patch :update, params: { id: @learning_path, learning_path: @updated_learning_path }
    assert_redirected_to learning_path_path(assigns(:learning_path))
  end

  test "should add topics to learning_path" do
    sign_in @learning_path.user
    learning_path = learning_paths(:two)
    assert_no_difference('LearningPathTopic.count') do
      assert_difference('LearningPathTopicLink.count', 1) do
        assert_difference('learning_path.topics.count', 1) do
          patch :update, params: { learning_path: {
            topic_links_attributes: { '1': { topic_id: learning_path_topics(:goblet_things).id, order: 300 } } },
                                   id: learning_path.id }
        end
      end
    end

    links = assigns(:learning_path).topic_links
    assert_equal 2, links.length
    assert_equal 1, links[0].order
    assert_equal learning_path_topics(:good_and_bad), links[0].topic
    assert_equal 2, links[1].order
    assert_equal learning_path_topics(:goblet_things), links[1].topic
  end

  test "should remove topic from learning_path" do
    sign_in @learning_path.user
    learning_path = learning_paths(:two)
    assert_no_difference('LearningPathTopic.count') do
      assert_difference('LearningPathTopicLink.count', -1) do
        assert_difference('learning_path.topics.count', -1) do
          patch :update, params: { learning_path: {
            topic_links_attributes: { '1': { id: learning_path.topic_link_ids.first, _destroy: '1' } } },
                                   id: learning_path.id }
        end
      end
    end

    assert_empty assigns(:learning_path).topic_links
  end

  test "should modify items in learning_path" do
    sign_in @learning_path.user

    l1 = @learning_path.topic_links[0]
    l2 = @learning_path.topic_links[1]

    assert_no_difference('LearningPathTopicLink.count') do
      patch :update, params: { id: @learning_path.id, learning_path: { items_attributes: {
        '1': { id: l1.id, order: 0 },
        '2': { id: l2.id, order: 500 }
      } } }

      links = assigns(:learning_path).topic_links
      assert_equal 2, links.length
      assert_equal 1, links[0].order
      assert_equal learning_path_topics(:goblet_things), links[0].topic
      assert_equal 2, links[1].order
      assert_equal learning_path_topics(:good_and_bad), links[1].topic
    end
  end

  #DESTROY TEST
  test 'should destroy learning_path owned by user' do
    sign_in @learning_path.user
    assert_difference('LearningPath.count', -1) do
      delete :destroy, params: { id: @learning_path }
    end
    assert_redirected_to learning_paths_path
  end

  test 'should destroy learning_path when administrator' do
    sign_in users(:admin)
    assert_difference('LearningPath.count', -1) do
      delete :destroy, params: { id: @learning_path }
    end
    assert_redirected_to learning_paths_path
  end

  test 'should not destroy learning_path not owned by user' do
    sign_in users(:another_regular_user)
    assert_no_difference('LearningPath.count') do
      delete :destroy, params: { id: @learning_path }
    end
    assert_response :forbidden
  end


  #CONTENT TESTS
  #BREADCRUMBS
  test 'breadcrumbs for learning_paths index' do
    get :index
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li[class=active]', text: /Learning paths/, count: 1
    end
  end

  test 'breadcrumbs for showing learning_path' do
    get :show, params: { id: @learning_path }
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li', text: /Learning paths/, count: 1 do
        assert_select 'a[href=?]', learning_paths_url, count: 1
      end
      assert_select 'li[class=active]', text: /#{@learning_path.title}/, count: 1
    end
  end

  test 'breadcrumbs for editing learning_path' do
    sign_in users(:admin)
    get :edit, params: { id: @learning_path }
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li', text: /Learning paths/, count: 1 do
        assert_select 'a[href=?]', learning_paths_url, count: 1
      end
      assert_select 'li', text: /#{@learning_path.title}/, count: 1 do
        assert_select 'a[href=?]', learning_path_url(@learning_path), count: 1
      end
      assert_select 'li[class=active]', text: /Edit/, count: 1
    end
  end

  test 'breadcrumbs for creating new learning_path' do
    sign_in users(:admin)
    get :new
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li', text: /Learning paths/, count: 1 do
        assert_select 'a[href=?]', learning_paths_url, count: 1
      end
      assert_select 'li[class=active]', text: /New/, count: 1
    end
  end

  #OTHER CONTENT
  test 'learning path lists topics' do
    sign_in(users(:regular_user))

    get :show, params: { id: @learning_path }

    assert_response :success
    assert_select '.learning-path-topics' do
      assert_select '.learning-path-topic', count: 2
    end
  end

  test 'learning_path has correct layout' do
    sign_out :user

    get :show, params: { id: @learning_path }

    assert_response :success
    assert_select 'a.btn[href=?]', edit_learning_path_path(@learning_path), count: 0 #No Edit
    assert_select 'a.btn[href=?]', learning_path_path(@learning_path), count: 0 #No Edit
  end

  test 'do not show action buttons when not owner or admin' do
    sign_in users(:another_regular_user)

    get :show, params: { id: @learning_path }

    assert_select 'a.btn[href=?]', edit_learning_path_path(@learning_path), count: 0 #No Edit
    assert_select 'a.btn[href=?]', learning_path_path(@learning_path), count: 0 #No Edit
  end

  test 'show action buttons when curator' do
    sign_in users(:curator)

    get :show, params: { id: @learning_path }

    assert_select 'a.btn[href=?]', edit_learning_path_path(@learning_path), count: 1
    assert_select 'a.btn[href=?]', learning_path_path(@learning_path), text: 'Delete', count: 1
  end

  test 'show action buttons when admin' do
    sign_in users(:admin)

    get :show, params: { id: @learning_path }

    assert_select 'a.btn[href=?]', edit_learning_path_path(@learning_path), count: 1
    assert_select 'a.btn[href=?]', learning_path_path(@learning_path), text: 'Delete', count: 1
  end

  #API Actions
  test 'should not allow access to private learning_paths' do
    sign_in users(:regular_user)
    get :show, params: { id: learning_paths(:in_development_learning_path) }
    assert_response :forbidden
  end

  test 'should allow access to private learning_paths if privileged' do
    sign_in users(:curator)
    get :show, params: { id: learning_paths(:in_development_learning_path) }
    assert_response :success
  end

  test 'should hide private learning_paths from index' do
    get :index
    assert_response :success
    assert_not_includes assigns(:learning_paths).map(&:id), learning_paths(:in_development_learning_path).id
  end

  test 'should not hide private learning_paths from index from admin' do
    sign_in users(:admin)
    get :index
    assert_response :success
    assert_includes assigns(:learning_paths).map(&:id), learning_paths(:in_development_learning_path).id
  end

  test 'should log changes when updating a learning_path' do
    sign_in @learning_path.user
    assert @learning_path.save
    @learning_path.activities.destroy_all

    # 3 = 2 for parameters + 1 for update
    assert_difference('PublicActivity::Activity.count', 3) do
      patch :update, params: { id: @learning_path, learning_path: @updated_learning_path }
    end

    assert_equal 1, @learning_path.activities.where(key: 'learning_path.update').count
    assert_equal 2, @learning_path.activities.where(key: 'learning_path.update_parameter').count

    parameters = @learning_path.activities.where(key: 'learning_path.update_parameter').map(&:parameters)
    title_activity = parameters.detect { |p| p[:attr] == 'title' }
    description_activity = parameters.detect { |p| p[:attr] == 'description' }

    assert_equal 'New title', title_activity[:new_val]
    assert_equal 'New description', description_activity[:new_val]

    old_controller = @controller
    @controller = ActivitiesController.new

    get :index, params: { learning_path_id: @learning_path }, xhr: true

    assert_select '.activity', count: 4 # +1 because they are wrapped in a .activity div for some reason...

    @controller = old_controller
  end

  test 'should allow collaborator to edit' do
    user = users(:another_regular_user)
    @learning_path.collaborators << user
    sign_in user

    assert_difference('LearningPathTopicLink.count', -1) do
      patch :update, params: { learning_path: {
        topic_links_attributes: { '1': { id: @learning_path.topic_link_ids.first, _destroy: '1' } } },
                               id: @learning_path.id }
      assert_redirected_to learning_path_path(assigns(:learning_path))
    end

  end

  test 'should not allow non-collaborator to edit' do
    user = users(:another_regular_user)
    sign_in user

    assert_no_difference('LearningPathTopicLink.count') do
      patch :update, params: { learning_path: { topic_links_attributes: { '1': { topic_id: learning_path_topics(:good_and_bad), order: 1 } } }, id: @learning_path.id }
    end

    assert_response :forbidden
  end

  test 'should render learning_path items in order' do
    get :show, params: { id: @learning_path }

    assert_response :success

    assert_select '.learning-path-topics .learning-path-topic:nth-child(1)' do
      assert_select '.learning-path-topic-title h4', text: 'Another Learning Path Topic'
      assert_select '.learning-path-topic-order', text: '1'
      assert_select '.learning-path-topic-contents .description', text: 'Some text'
    end

    assert_select '.learning-path-topics .learning-path-topic:nth-child(2)' do
      assert_select '.learning-path-topic-title h4', text: 'My Learning Path Topic'
      assert_select '.learning-path-topic-order', text: '2'
      assert_select '.learning-path-topic-contents .description', text: 'MyText'
    end
  end

  test 'should render learning_path items in order as json-api' do
    skip 'JSON not yet implemented'
    materials = [materials(:good_material), materials(:biojs), materials(:interpro)]
    events = [events(:two), events(:one)]
    @learning_path.items.create!(resource: materials[0], order: 2, comment: 'A good material')
    @learning_path.items.create!(resource: materials[1], order: 1, comment: 'Start here')
    @learning_path.items.create!(resource: materials[2], order: 3, comment: 'End here')
    @learning_path.items.create!(resource: events[0], order: 2, comment: 'End here')
    @learning_path.items.create!(resource: events[1], order: 1, comment: 'Start here')

    get :show, params: { id: @learning_path, format: :json_api }

    assert_response :success
    assert assigns(:learning_path)
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
