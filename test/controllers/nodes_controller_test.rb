require 'test_helper'

class NodesControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    @node = nodes(:good)
  end

  test "should get index" do
    get :index
    assert_response :success
    #assert_not_nil assigns(:nodes)
  end
=begin

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create node" do
    assert_difference('Node.count') do
      post :create, node: { carousel_images: @node.carousel_images, country_code: @node.country_code, home_page: @node.home_page, institutions: @node.institutions, member_status: @node.member_status, name: @node.name, staff: @node.staff,  trc: @node.trc, trc_email: @node.trc_email, twitter: @node.twitter }
    end

    assert_redirected_to node_path(assigns(:node))
  end

  test "should show node" do
    get :show, id: @node
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @node
    assert_response :success
  end

  test "should update node" do
    patch :update, id: @node, node: { carousel_images: @node.carousel_images, country_code: @node.country_code, home_page: @node.home_page, institutions: @node.institutions, member_status: @node.member_status, name: @node.name, staff: @node.staff, trc: @node.trc, trc_email: @node.trc_email, twitter: @node.twitter }
    assert_redirected_to node_path(assigns(:node))
  end

  test "should destroy node" do
    assert_difference('Node.count', -1) do
      delete :destroy, id: @node
    end

    assert_redirected_to nodes_path
  end
=end
end
