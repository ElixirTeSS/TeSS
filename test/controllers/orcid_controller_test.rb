require 'test_helper'

class OrcidControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'authenticate orcid logged-in user' do
    sign_in users(:regular_user)

    post :authenticate

    assert_redirected_to /https:\/\/sandbox\.orcid\.org\/oauth\/authorize\?.+/
    params = Rack::Utils.parse_query(URI.parse(response.location).query)
    assert_equal "#{TeSS::Config.base_url}/orcid/callback", params['redirect_uri']
    assert_nil params['state']
  end

  test 'authenticating orcid in space uses root app redirect URI and sets space state' do
    plant_space = spaces(:plants)
    with_host(plant_space.host) do
      sign_in users(:regular_user)

      post :authenticate

      assert_redirected_to /https:\/\/sandbox\.orcid\.org\/oauth\/authorize\?.+/
      params = Rack::Utils.parse_query(URI.parse(response.location).query)
      assert_equal "#{TeSS::Config.base_url}/orcid/callback", params['redirect_uri']
      assert_equal "space_id:#{plant_space.id}", params['state']
    end
  end

  test 'do not authenticate orcid if user not logged-in' do
    post :authenticate

    assert_redirected_to new_user_session_path
  end

  test 'handle callback and assign orcid if free' do
    mock_images
    user = users(:regular_user)
    assert user.profile.orcid.blank?
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

  test 'handle callback and assign orcid even if already used' do
    mock_images
    user = users(:regular_user)
    existing_orcid_user = users(:trainer_user)
    assert existing_orcid_user.profile.orcid_authenticated?
    sign_in user

    VCR.use_cassette('orcid/get_token_existing_orcid') do
      get :callback, params: { code: '123xyz' }
    end

    profile = user.profile.reload
    assert_equal '0000-0002-1825-0097', profile.orcid
    assert profile.orcid_authenticated?
    refute existing_orcid_user.reload.profile.orcid_authenticated?
    assert_redirected_to user
    assert flash[:error].blank?
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

    VCR.use_cassette('orcid/error_500') do
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

  test 'do not authenticate orcid if feature not enabled' do
    Rails.application.config.secrets.stub(:orcid, nil) do
      sign_in users(:regular_user)

      assert_raises(ActionController::RoutingError) do
        post :authenticate
      end
    end
  end

  test 'do not handle orcid callback if feature not enabled' do
    Rails.application.config.secrets.stub(:orcid, nil) do
      mock_images
      user = users(:regular_user)
      sign_in user

      VCR.use_cassette('orcid/get_token_unauth_orcid') do
        assert_raises(ActionController::RoutingError) do
          get :callback, params: { code: '123xyz' }
        end
        profile = user.profile.reload
        refute profile.orcid_authenticated?
      end
    end
  end

  test 'redirect to subdomain space in callback' do
    space = spaces(:astro)
    space.update!(host: 'space.example.com')
    mock_images
    user = users(:regular_user)
    assert user.profile.orcid.blank?
    sign_in user

    VCR.use_cassette('orcid/get_token_free_orcid') do
      get :callback, params: { code: '123xyz', state: "space_id:#{space.id}" }
    end

    profile = user.profile.reload
    assert_equal '0009-0006-0987-5702', profile.orcid
    assert profile.orcid_authenticated?
    assert_redirected_to user_url(user, host: 'space.example.com')
    assert response.headers['Location'].starts_with?('http://space.example.com/users/')
    assert flash[:error].blank?
  end

  test 'do not redirect to non-subdomain space in callback' do
    space = spaces(:astro)
    space.update!(host: 'space.golf.com')
    mock_images
    user = users(:regular_user)
    assert user.profile.orcid.blank?
    sign_in user

    VCR.use_cassette('orcid/get_token_free_orcid') do
      get :callback, params: { code: '123xyz', state: "space_id:#{space.id}" }
    end

    profile = user.profile.reload
    assert_equal '0009-0006-0987-5702', profile.orcid
    assert profile.orcid_authenticated?
    assert_redirected_to user
    refute response.headers['Location'].starts_with?('http://space.golf.com/users/')
    assert flash[:error].blank?
  end

  test 'ignore bad space when redirecting in callback' do
    mock_images
    user = users(:regular_user)
    assert user.profile.orcid.blank?
    sign_in user

    VCR.use_cassette('orcid/get_token_free_orcid') do
      get :callback, params: { code: '123xyz', state: "space_id:banana🍌" }
    end

    profile = user.profile.reload
    assert_equal '0009-0006-0987-5702', profile.orcid
    assert profile.orcid_authenticated?
    assert_redirected_to user
    assert flash[:error].blank?
  end
end
