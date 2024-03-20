# frozen_string_literal: true

# OpenID Connect configuration for AAF (Australia)
unless Rails.application.secrets.dig(:oidc, :client_id).blank?
  Devise.omniauth :oidc, {
    logo: 'dresa/aaf_service_223x54.png',
    name: :oidc,
    issuer: Rails.application.secrets.oidc[:issuer],
    strategy_class: OmniAuth::Strategies::OpenIDConnect,
    scope: %i[openid email profile],
    response_type: 'code',                                 # default is 'code'
    discovery: true,                                       # default is false
    send_nonce: true,
    client_signing_alg: :RS256,
    client_options: {
      redirect_uri: Rails.application.secrets.oidc[:redirect_uri],
      identifier: Rails.application.secrets.oidc[:client_id],
      secret: Rails.application.secrets.oidc[:secret],
      host: Rails.application.secrets.oidc[:host],
      scheme: 'https',
      port: 443,
      authorization_endpoint: '/providers/op/authorize',
      userinfo_endpoint: '/providers/op/userinfo',
      token_endpoint: '/providers/op/token',
      jwks_uri: '/providers/op/jwks'
    }
  }
end
