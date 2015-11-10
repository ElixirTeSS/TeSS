require 'test_helper'

class ContentProvidersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    @content_provider = content_providers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:content_providers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create content_provider" do
    sign_in users(:regular_user)
    assert_difference('ContentProvider.count') do
      post :create, content_provider: { title: @content_provider.title, url: @content_provider.url, logo_url: @content_provider.logo_url, description: @content_provider.description }
    end

    assert_redirected_to content_provider_path(assigns(:content_provider))
  end

  test "should show content_provider" do
    get :show, id: @content_provider
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @content_provider
    assert_response :success
  end

  test "should update content_provider" do
    sign_in users(:regular_user)
    patch :update, id: @content_provider, content_provider: { title: @content_provider.title, url: @content_provider.url, logo_url: @content_provider.logo_url, description: @content_provider.description }
    assert_redirected_to content_provider_path(assigns(:content_provider))
  end

  test "should destroy content_provider" do
    sign_in users(:regular_user)
    post :create, content_provider: { title: @content_provider.title, url: @content_provider.url, logo_url: @content_provider.logo_url, description: @content_provider.description }
    assert_difference('ContentProvider.count', -1) do
      delete :destroy, id: @content_provider
    end

    assert_redirected_to content_providers_path
  end
end
