# OpenID Connect configuration for AAF (Australia)
unless Rails.application.config.secrets.dig(:oidc, :client_id).blank?
  Devise.omniauth :oidc, {
    logo: 'dresa/aaf_service_223x54.png',
    name: :oidc,
    issuer: Rails.application.config.secrets.oidc[:issuer],
    strategy_class: OmniAuth::Strategies::OpenIDConnect,
    scope: [:openid, :email, :profile],
    response_type: 'code',                                 # default is 'code'
    discovery: true,                                       # default is false
    send_nonce: true,
    client_signing_alg: :RS256,
    client_options: {
      redirect_uri: Rails.application.config.secrets.oidc[:redirect_uri],
      identifier: Rails.application.config.secrets.oidc[:client_id],
      secret: Rails.application.config.secrets.oidc[:secret],
      host: Rails.application.config.secrets.oidc[:host],
      scheme: 'https',
      port: 443,
      authorization_endpoint: '/providers/op/authorize',
      userinfo_endpoint: '/providers/op/userinfo',
      token_endpoint: '/providers/op/token',
      jwks_uri: '/providers/op/jwks',
    }
  }
end