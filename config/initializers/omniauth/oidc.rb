# OpenID Connect configuration
unless Rails.application.config.secrets.dig(:oidc, :client_id).blank?
  Devise.omniauth :openid_connect, {
    name: :oidc,
    label: Rails.application.config.secrets.oidc[:label],
    logo: Rails.application.config.secrets.oidc[:logo],
    issuer: Rails.application.config.secrets.oidc[:issuer],
    strategy_class: OmniAuth::Strategies::OpenIDConnect,
    scope: [:openid, :email, :profile],
    response_type: :code,
    discovery: true,
    client_options: {
      identifier: Rails.application.config.secrets.oidc[:client_id],
      secret: Rails.application.config.secrets.oidc[:secret],
      redirect_uri: Rails.application.config.secrets.oidc[:redirect_uri].presence ||
        "#{TeSS::Config.base_url.chomp('/')}/users/auth/oidc/callback"
    }
  }
end
