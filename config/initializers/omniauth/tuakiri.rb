# OpenID Connect configuration for Tuakiri (New Zealand)
unless Rails.application.secrets.dig(:oidc, :client_id).blank?
  Devise.omniauth :oidc2, {
    name: :oidc2,
    issuer: Rails.application.secrets.oidc2[:issuer],
    strategy_class: OmniAuth::Strategies::OpenIDConnect,
    scope: [:openid, :email, :profile],
    response_type: :code,                                  # default is 'code'
    discovery: true,                                       # default is false
    send_nonce: true,
    client_signing_alg: :RS256,
    client_options: {
      redirect_uri: Rails.application.secrets.oidc2[:redirect_uri],
      identifier: Rails.application.secrets.oidc2[:client_id],
      secret: Rails.application.secrets.oidc2[:secret],
      host: Rails.application.secrets.oidc2[:host],
      scheme: 'https',
      port: 443,
      authorization_endpoint: '/Saml2/OIDC/authorization',
      userinfo_endpoint: '/OIDC/userinfo',
      token_endpoint: '/OIDC/token',
      jwks_uri: '/OIDC/jwks',
    }
  }
end