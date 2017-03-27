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

  test "should get index as json" do
    get :index, format: :json
    assert_response :success
    assert_not_empty assigns(:workflows)
  end

  test "should get new" do
    sign_in users(:admin)

    get :new
    assert_response :success
  end

  test "should create workflow" do
    sign_in users(:admin)

    assert_difference('Workflow.count') do
      post :create, workflow: { description: @workflow.description, title: @workflow.title,
          workflow_content: @workflow.workflow_content }
    end

    assert_redirected_to workflow_path(assigns(:workflow))
  end

  test "should show workflow" do
    get :show, id: @workflow
    assert_response :success
    assert_includes response.headers.keys, 'X-Frame-Options', 'X-Frame-Options header should be present in all actions except `embed`'
    assert assigns(:workflow)
  end

  test "should show workflow as json" do
    get :show, id: @workflow, format: :json
    assert_response :success
    assert assigns(:workflow)
  end

  test "should show embedded workflow" do
    get :embed, id: @workflow
    assert_response :success
    assert_select '.embedded-container', count: 1
    assert_not_includes response.headers.keys, 'X-Frame-Options', 'X-Frame-Options header should be removed to allow embedding in iframes'
  end

  test "should not show embedded private workflow" do
    get :embed, id: workflows(:private_workflow)
    assert_response :forbidden
    assert_select '.embedded-container', count: 0
  end

  test "should get edit" do
    sign_in users(:admin)

    get :edit, id: @workflow
    assert_response :success
  end

  test "should update workflow" do
    sign_in users(:admin)

    patch :update, id: @workflow, workflow: { description: @workflow.description, title: 'hello',
                                              workflow_content: @workflow.workflow_content }
    assert_redirected_to workflow_path(assigns(:workflow))
    assert_equal 'hello', assigns(:workflow).title
  end

  test "should destroy workflow" do
    sign_in users(:admin)

    assert_difference('Workflow.count', -1) do
      delete :destroy, id: @workflow
    end

    assert_redirected_to workflows_path
  end

  test 'should allow collaborator to edit' do
    user = users(:another_regular_user)
    @workflow.collaborators << user
    sign_in user

    get :edit, id: @workflow
    assert_response :success
  end

  test 'should not allow non-collaborator to edit' do
    user = users(:another_regular_user)
    sign_in user

    get :edit, id: @workflow
    assert_response :forbidden
  end

  test 'should not allow collaborator to delete' do
    user = users(:another_regular_user)
    @workflow.collaborators << user
    sign_in user

    assert_no_difference('Workflow.count') do
      delete :destroy, id: @workflow
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

end
