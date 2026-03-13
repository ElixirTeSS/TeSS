class OrcidController < ApplicationController
  include SpaceRedirect

  before_action :orcid_auth_enabled
  before_action :authenticate_user!
  before_action :set_oauth_client, only: [:authenticate, :callback]

  # Faraday::ParsingError occurs in rack-oauth2 if the response does not contain JSON
  rescue_from(Rack::OAuth2::Client::Error, Faraday::ParsingError) do
    handle_error(:unprocessable_entity, t('orcid.error'))
  end

  def authenticate
    params = Space.current_space&.default? ? {} : { state: "space_id:#{Space.current_space.id}" }
    redirect_to @oauth2_client.authorization_uri(scope: '/authenticate', **params), allow_other_host: true
  end

  def callback
    @oauth2_client.authorization_code = params[:code]
    token = Rack::OAuth2::AccessToken::Bearer.new(access_token: @oauth2_client.access_token!)
    if params[:state].present?
      m = params[:state].match(/space_id:(\d+)/)
      space = Space.find_by_id(m[1]) if m
    end
    orcid = token.access_token&.raw_attributes['orcid']
    respond_to do |format|
      profile = current_user.profile
      if orcid.present?
        if profile.authenticate_orcid(orcid)
          flash[:notice] = t('orcid.authentication_success')
        else
          flash[:error] = profile.errors.full_messages.join(', ')
        end
      else
        flash[:error] = t('orcid.authentication_failure')
      end
      format.html { redirect_to_space(user_path(current_user), space) }
    end
  end

  private

  def set_oauth_client
    config = Rails.application.config.secrets.orcid
    @oauth2_client ||= Rack::OAuth2::Client.new(
      identifier: config[:client_id],
      secret: config[:secret],
      redirect_uri: config[:redirect_uri].presence || orcid_callback_url(host: TeSS::Config.base_uri.host),
      authorization_endpoint: '/oauth/authorize',
      token_endpoint: '/oauth/token',
      host: config[:host].presence || (Rails.env.production? ? 'orcid.org' : 'sandbox.orcid.org')
    )
  end

  def orcid_auth_enabled
    unless TeSS::Config.orcid_authentication_enabled?
      raise ActionController::RoutingError.new('Feature not enabled')
    end
  end
end
