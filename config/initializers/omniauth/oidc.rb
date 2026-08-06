# OpenID Connect configuration
unless Rails.application.config.secrets.dig(:oidc, :client_id).blank?
  redirect_uris = TessOmniauthRedirectUris.normalize(
    Rails.application.config.secrets.oidc[:redirect_uri],
    "#{TeSS::Config.base_url.chomp('/')}/users/auth/oidc/callback"
  )

  Devise.omniauth :openid_connect, {
    name: :oidc,
    label: Rails.application.config.secrets.oidc[:label],
    logo: Rails.application.config.secrets.oidc[:logo],
    issuer: Rails.application.config.secrets.oidc[:issuer],
    strategy_class: OmniAuth::Strategies::HostRedirectOpenIDConnect,
    scope: [:openid, :email, :profile],
    response_type: :code,
    discovery: true,
    redirect_uris: redirect_uris,
    client_options: {
      identifier: Rails.application.config.secrets.oidc[:client_id],
      secret: Rails.application.config.secrets.oidc[:secret],
      redirect_uri: redirect_uris.first
    }
  }
end
