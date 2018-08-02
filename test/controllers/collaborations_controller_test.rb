require 'test_helper'

class CollaborationsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @workflow = workflows(:one)
    @workflow.collaborators << users(:another_regular_user)
    @workflow.collaborators << users(:collaborative_user)
  end

  test "should list collaborations" do
    sign_in(@workflow.user)

    get :index, params: { format: :json, workflow_id: @workflow.id }
    assert_response :success
    collaborations = JSON.parse(@response.body)

    assert_equal 2, collaborations.length
    assert_includes collaborations.map { |e| e['user']['id'] }, users(:another_regular_user).id
    assert_includes collaborations.map { |e| e['user']['id'] }, users(:collaborative_user).id
  end

  test "should not list collaborations if not a manager" do
    sign_in(users(:another_regular_user))

    get :index, params: { format: :json, workflow_id: @workflow.id }
    assert_response :forbidden
  end

  test "should add collaborator" do
    sign_in(@workflow.user)

    assert_difference('Collaboration.count', 1) do
      post :create, params: { format: :json, workflow_id: @workflow.id, collaboration: { user_id: users(:non_collaborative_user).id } }
    end

    assert_response :success
    collaboration = JSON.parse(@response.body)

    assert_equal users(:non_collaborative_user).id, collaboration['user']['id']
  end

  test "should not add duplicate collaborator" do
    sign_in(@workflow.user)

    assert_no_difference('Collaboration.count') do
      post :create, params: { format: :json, workflow_id: @workflow.id, collaboration: { user_id: users(:collaborative_user).id } }
    end

    assert_response :unprocessable_entity
    assert JSON.parse(@response.body)['errors']['user'].join.include?('already a collaborator')
  end

  test "should not add collaborator if not a manager" do
    sign_in(users(:another_regular_user))

    assert_no_difference('Collaboration.count') do
      post :create, params: { format: :json, workflow_id: @workflow.id, collaboration: { user_id: users(:non_collaborative_user).id } }
    end

    assert_response :forbidden
  end

  test "should delete collaborator" do
    sign_in(@workflow.user)
    collaboration = @workflow.collaborations.where(user_id: users(:another_regular_user).id).first

    assert_difference('Collaboration.count', -1) do
      delete :destroy, params: { format: :json, workflow_id: @workflow.id, id: collaboration.id }
    end

    assert_response :success

    assert_not_includes @workflow.collaborators.reload, users(:another_regular_user)
  end

  test "should not delete collaborator if not a manager" do
    sign_in(users(:another_regular_user))
    collaboration = @workflow.collaborations.where(user_id: users(:another_regular_user).id).first

    assert_no_difference('Collaboration.count') do
      delete :destroy, params: { format: :json, workflow_id: @workflow.id, id: collaboration.id }
    end

    assert_response :forbidden
  end

end
