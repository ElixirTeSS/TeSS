# Secondary OpenID Connect configuration
unless Rails.application.config.secrets.dig(:oidc2, :client_id).blank?
  redirect_uris = TessOmniauthRedirectUris.normalize(
    Rails.application.config.secrets.oidc2[:redirect_uri],
    "#{TeSS::Config.base_url.chomp('/')}/users/auth/oidc2/callback"
  )

  Devise.omniauth :openid_connect, {
    name: :oidc2,
    label: Rails.application.config.secrets.oidc2[:label],
    logo: Rails.application.config.secrets.oidc2[:logo],
    issuer: Rails.application.config.secrets.oidc2[:issuer],
    strategy_class: OmniAuth::Strategies::HostRedirectOpenIDConnect,
    scope: [:openid, :email, :profile],
    response_type: :code,
    discovery: true,
    redirect_uris: redirect_uris,
    client_options: {
      identifier: Rails.application.config.secrets.oidc2[:client_id],
      secret: Rails.application.config.secrets.oidc2[:secret],
      redirect_uri: redirect_uris.first
    }
  }
end
