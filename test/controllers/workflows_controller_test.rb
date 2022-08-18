require 'test_helper'

class WorkflowsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @workflow = workflows(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_empty assigns(:workflows)
  end

  test 'should get index with solr enabled' do
    begin
      TeSS::Config.solr_enabled = true

      Workflow.stub(:search_and_filter, MockSearch.new(Workflow.all)) do
        get :index, params: { q: 'bananas', keywords: 'fruit' }
        assert_response :success
        assert_not_empty assigns(:workflows)
      end
    ensure
      TeSS::Config.solr_enabled = false
    end
  end

  test "should get index as json" do
    @workflow.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @workflow.save!

    get :index, params: { format: :json }
    assert_response :success
    assert_not_empty assigns(:workflows)
  end

  test 'should get index as json-api' do
    get :index, params: { format: :json_api }
    assert_response :success
    assert_not_nil assigns(:workflows)
    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert body['data'].any?
    assert body['meta']['results-count'] > 0
    assert body['meta'].key?('query')
    assert body['meta'].key?('facets')
    assert body['meta'].key?('available-facets')
    assert_equal workflows_path, body['links']['self']
  end

  test 'should get new' do
    sign_in users(:admin)
    get :new
    assert_response :success
  end

  test 'should not get new page for basic users' do
    sign_in users(:basic_user)
    get :new
    assert_response :forbidden
  end

  test "should create workflow" do
    sign_in users(:admin)

    assert_difference('Workflow.count') do
      post :create, params: {
          workflow: {
              description: @workflow.description,
              title: @workflow.title,
              workflow_content: @workflow.workflow_content
          }
      }
    end

    assert_redirected_to workflow_path(assigns(:workflow))
  end

  test "should show workflow" do
    get :show, params: { id: @workflow }
    assert_response :success
    assert_includes response.headers.keys, 'X-Frame-Options', 'X-Frame-Options header should be present in all actions except `embed`'
    assert assigns(:workflow)
  end

  test "should show workflow as json" do
    @workflow.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @workflow.save!

    get :show, params: { id: @workflow, format: :json }
    assert_response :success
    assert assigns(:workflow)
  end

  test "should show embedded workflow" do
    get :embed, params: { id: @workflow }
    assert_response :success
    assert_select '.embedded-container', count: 1
    assert_not_includes response.headers.keys, 'X-Frame-Options', 'X-Frame-Options header should be removed to allow embedding in iframes'
  end

  test "should not show embedded private workflow" do
    get :embed, params: { id: workflows(:private_workflow) }
    assert_response :forbidden
    assert_select '.embedded-container', count: 0
  end

  test 'should show workflow as json-api' do
    get :show, params: { id: @workflow, format: :json_api }
    assert_response :success
    assert assigns(:workflow)

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert_equal @workflow.title, body['data']['attributes']['title']
    assert_equal workflow_path(assigns(:workflow)), body['data']['links']['self']
  end

  test "should get edit" do
    sign_in users(:admin)

    get :edit, params: { id: @workflow }
    assert_response :success
  end

  test "should update workflow" do
    sign_in users(:admin)

    patch :update, params: {
        id: @workflow,
        workflow: {
            description: @workflow.description,
            title: 'hello',
            workflow_content: @workflow.workflow_content
        }
    }
    assert_redirected_to workflow_path(assigns(:workflow))
    assert_equal 'hello', assigns(:workflow).title
  end

  test "should destroy workflow" do
    sign_in users(:admin)

    assert_difference('Workflow.count', -1) do
      delete :destroy, params: { id: @workflow }
    end

    assert_redirected_to workflows_path
  end

  test 'should allow collaborator to edit' do
    user = users(:another_regular_user)
    @workflow.collaborators << user
    sign_in user

    get :edit, params: { id: @workflow }
    assert_response :success
  end

  test 'should not allow non-collaborator to edit' do
    user = users(:another_regular_user)
    sign_in user

    get :edit, params: { id: @workflow }
    assert_response :forbidden
  end

  test 'should not allow collaborator to delete' do
    user = users(:another_regular_user)
    @workflow.collaborators << user
    sign_in user

    assert_no_difference('Workflow.count') do
      delete :destroy, params: { id: @workflow }
    end

    assert_response :forbidden
  end

  test 'should show private workflows in index for admin' do
    sign_in users(:admin)

    get :index

    assert_response :success
    assert_includes assigns(:workflows).map(&:id), workflows(:private_workflow).id
    assert_includes assigns(:workflows).map(&:id), workflows(:collaborated_workflow).id
  end

  test 'should show private workflow in index to collaborator' do
    sign_in users(:another_regular_user)

    get :index

    assert_response :success
    assert_includes assigns(:workflows).map(&:id), workflows(:collaborated_workflow).id
    assert_not_includes assigns(:workflows).map(&:id), workflows(:private_workflow).id
  end

  test 'should not show private workflow in index to not logged-in user' do
    get :index

    assert_response :success
    assert_not_includes assigns(:workflows).map(&:id), workflows(:collaborated_workflow).id
    assert_not_includes assigns(:workflows).map(&:id), workflows(:private_workflow).id
  end

  test 'should show private workflow in index to owner' do
    sign_in users(:regular_user)

    get :index

    assert_response :success
    assert_includes assigns(:workflows).map(&:id), workflows(:collaborated_workflow).id
    assert_includes assigns(:workflows).map(&:id), workflows(:private_workflow).id
  end

  test 'should fork workflow' do
    sign_in users(:another_regular_user)

    get :fork, params: { id: @workflow.id }
    assert_response :success
    assert_select '#workflow_title[value=?]', "Fork of #{@workflow.title}"
  end

  test 'should log diagram modification' do
    user = users(:admin)
    sign_in user

    assert_difference(-> { @workflow.activities.count }) do
      patch :update, params: {
          id: @workflow,
          workflow: {
              description: @workflow.description,
              title: @workflow.title,
              public: @workflow.public,
              workflow_content: workflows(:two).workflow_content.to_json
          }
      }
    end

    assert_redirected_to workflow_path(assigns(:workflow))
    assert_equal user, @workflow.activities.last.owner
  end

  test 'should show identifiers dot org button for workflow' do
    get :show, params: { id: @workflow }

    assert_response :success
    assert_select '.identifiers-button'
    assert_select '#identifiers-link[value=?]', "http://example.com/identifiers/banana:w#{@workflow.id}"
  end
end
