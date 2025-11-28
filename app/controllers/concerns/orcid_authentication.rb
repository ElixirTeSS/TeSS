module OrcidAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :set_oauth2_client, only: [:authenticate_orcid, :orcid_callback]
  end

  def authenticate_orcid
    redirect_to @oauth2_client.authorization_uri(scope: '/authenticate'), allow_other_host: true
  end

  def orcid_callback
    @oauth2_client.authorization_code = params[:code]
    token = Rack::OAuth2::AccessToken::Bearer.new(access_token: @oauth2_client.access_token!)
    orcid = token.access_token&.raw_attributes['orcid']
    respond_to do |format|
      profile = current_user.profile
      if profile.authenticate_orcid(orcid)
        flash[:notice] = t('orcid.authentication_success')
      else
        flash[:error] = profile.errors.full_messages.join(', ')
      end
      format.html { redirect_to current_user }
    end
  end

  private

  def set_oauth2_client
    config = Rails.application.config.secrets.orcid
    @oauth2_client ||= Rack::OAuth2::Client.new(
      identifier: config[:client_id],
      secret: config[:secret],
      redirect_uri: 'https://localhost:3001/orcid/callback',#config[:redirect_uri].presence || orcid_callback_url,
      authorization_endpoint: '/oauth/authorize',
      token_endpoint: '/oauth/token',
      host: config[:host].presence || (Rails.env.production? ? 'orcid.org' : 'sandbox.orcid.org')
    )
  end
end
