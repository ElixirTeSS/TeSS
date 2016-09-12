require 'test_helper'

class WorkflowsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    @workflow = workflows(:one)
  end

  test "should get index" do
    get :index
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

end
