# OpenID Connect configuration for LS Login nee Elixir AAI
unless Rails.application.config.secrets.dig(:elixir_aai, :client_id).blank?
  Devise.omniauth :openid_connect, {
    logo: 'ls-login.png',
    name: :elixir_aai,
    scope: [:openid, :email, :profile],
    response_type: 'code',
    issuer: 'https://login.aai.lifescience-ri.eu/oidc/',
    discovery: true,
    client_options: {
      identifier: Rails.application.config.secrets.elixir_aai[:client_id],
      secret: Rails.application.config.secrets.elixir_aai[:secret],
      # Wish I could use the url helper for this! (user_elixir_aai_omniauth_callback_url)
      redirect_uri: "#{TeSS::Config.base_url.chomp('/')}/users/auth/elixir_aai/callback",
    }
  }
end