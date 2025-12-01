require 'test_helper'

class OrcidControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'authenticate orcid logged-in user' do
    sign_in users(:regular_user)

    post :authenticate

    assert_redirected_to /https:\/\/sandbox\.orcid\.org\/oauth\/authorize\?.+/
  end

  test 'do not authenticate orcid if user not logged-in' do
    post :authenticate

    assert_redirected_to new_user_session_path
  end

  test 'handle callback and assign orcid if free' do
    mock_images
    user = users(:regular_user)
    sign_in user

    VCR.use_cassette('orcid/get_token_free_orcid') do
      get :callback, params: { code: '123xyz' }
    end

    profile = user.profile.reload
    assert_equal '0009-0006-0987-5702', profile.orcid
    assert profile.orcid_authenticated?
    assert_redirected_to user
  end

  test 'handle callback and assign orcid if unauthenticated' do
    mock_images
    user = users(:regular_user)
    sign_in user

    VCR.use_cassette('orcid/get_token_unauth_orcid') do
      get :callback, params: { code: '123xyz' }
    end

    profile = user.profile.reload
    assert_equal '0000-0002-0048-3300', profile.orcid
    assert profile.orcid_authenticated?
    assert_redirected_to user
  end

  test 'handle callback but do not assign orcid if already used' do
    mock_images
    user = users(:regular_user)
    sign_in user

    VCR.use_cassette('orcid/get_token_existing_orcid') do
      get :callback, params: { code: '123xyz' }
    end

    profile = user.profile.reload
    assert profile.orcid.blank?
    refute profile.orcid_authenticated?
    assert_redirected_to user
    assert_includes flash[:error], 'ORCID has already been'
  end

  test 'do not handle callback if not logged-in' do
    mock_images

    get :callback, params: { code: '123xyz' }

    assert_redirected_to new_user_session_path
  end

  test 'handle unauth error during callback' do
    mock_images
    user = users(:regular_user)
    sign_in user

    VCR.use_cassette('orcid/error_unauth') do
      get :callback, params: { code: '123xyz' }
    end

    assert_response :unprocessable_entity
    assert_select '#error-message', text: /error occurred.+ORCID/
    profile = user.profile.reload
    assert profile.orcid.blank?
    refute profile.orcid_authenticated?
  end

  test 'handle unexpected error during callback' do
    mock_images
    user = users(:regular_user)
    sign_in user

    VCR.use_cassette('orcid/get_token_orcid_missing') do
      get :callback, params: { code: '123xyz' }
    end

    assert_response :unprocessable_entity
    assert_select '#error-message', text: /error occurred.+ORCID/
    profile = user.profile.reload
    assert profile.orcid.blank?
    refute profile.orcid_authenticated?
  end

  test 'handle missing orcid during callback' do
    mock_images
    user = users(:regular_user)
    sign_in user

    VCR.use_cassette('orcid/get_token_orcid_missing') do
      get :callback, params: { code: '123xyz' }
    end

    assert_redirected_to user
    assert_includes flash[:error], 'Failed to authenticat'
    profile = user.profile.reload
    assert profile.orcid.blank?
    refute profile.orcid_authenticated?
  end
end
