require 'test_helper'

class StarsControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  test "can star a resource" do
    sign_in users(:regular_user)
    material = materials(:good_material)

    assert_difference('Star.count') do
      post :create, params: { star: { resource_id: material.id, resource_type: material.class.name }, format: :json }
    end

    assert_response :success
  end

  test "does not add duplicate star to resource" do
    user = users(:regular_user)
    sign_in user
    material = materials(:good_material)
    user.stars.create(resource: material)

    assert_no_difference('Star.count') do
      post :create, params: { star: { resource_id: material.id, resource_type: material.class.name }, format: :json }
    end

    assert_response :success
  end

  test "can un-star resource" do
    user = users(:regular_user)
    sign_in user
    material = materials(:good_material)
    user.stars.create(resource: material)

    assert_difference('Star.count', -1) do
      delete :destroy, params: { star: { resource_id: material.id, resource_type: material.class.name }, format: :json }
    end

    assert_response :success
  end

  test "cannot star a resource if not logged in" do
    material = materials(:good_material)

    assert_no_difference('Star.count') do
      post :create, params: { star: { resource_id: material.id, resource_type: material.class.name }, format: :json }
    end

    assert_response :unauthorized
  end

  test "cannot create bad star" do
    user = users(:regular_user)
    sign_in user

    assert_no_difference('Star.count') do
      post :create, params: { star: { resource_id: Material.maximum(:id) + 1, resource_type: 'Material' }, format: :json }
    end

    assert_response :unprocessable_entity
  end

  test "can view list of stars" do
    user = users(:regular_user)
    sign_in user
    material = materials(:good_material)
    user.stars.create(resource: material)

    get :index

    assert_response :success
    assert_select '#materials div.search-results-count', text: "1 Material", count: 1
    assert_select '#materials a.list-card-heading[href=?]', material_path(material), text: material.title, count: 1
  end
end
