# OpenID Connect configuration for LS Login nee Elixir AAI
unless Rails.application.secrets.dig(:elixir_aai, :client_id).blank?
  Devise.omniauth :openid_connect, {
    logo: 'elixir/login-button-orange.png',
    name: :elixir_aai,
    scope: [:openid, :email, :profile],
    response_type: 'code',
    issuer: 'https://login.elixir-czech.org/oidc/',
    discovery: false,
    send_nonce: true,
    client_signing_alg: :RS256,
    client_jwk_signing_key: '{"keys":[{"kty":"RSA","e":"AQAB","kid":"rsa1","alg":"RS256","n":"uVHPfUHVEzpgOnDNi3e2pVsbK1hsINsTy_1mMT7sxDyP-1eQSjzYsGSUJ3GHq9LhiVndpwV8y7Enjdj0purywtwk_D8z9IIN36RJAh1yhFfbyhLPEZlCDdzxas5Dku9k0GrxQuV6i30Mid8OgRQ2q3pmsks414Afy6xugC6u3inyjLzLPrhR0oRPTGdNMXJbGw4sVTjnh5AzTgX-GrQWBHSjI7rMTcvqbbl7M8OOhE3MQ_gfVLXwmwSIoKHODC0RO-XnVhqd7Qf0teS1JiILKYLl5FS_7Uy2ClVrAYd2T6X9DIr_JlpRkwSD899pq6PR9nhKguipJE0qUXxamdY9nw"}]}',
    client_options: {
      identifier: Rails.application.secrets.elixir_aai[:client_id],
      secret: Rails.application.secrets.elixir_aai[:secret],
      # Wish I could use the url helper for this! (user_elixir_aai_omniauth_callback_url)
      redirect_uri: "#{TeSS::Config.base_url.chomp('/')}/users/auth/elixir_aai/callback",
      scheme: 'https',
      host: 'login.elixir-czech.org',
      port: 443,
      authorization_endpoint: '/oidc/authorize',
      token_endpoint: '/oidc/token',
      userinfo_endpoint: '/oidc/userinfo',
      jwks_uri: '/oidc/jwk',
    }
  }
end