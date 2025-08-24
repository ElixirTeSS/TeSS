# Secondary OpenID Connect configuration
unless Rails.application.config.secrets.dig(:oidc2, :client_id).blank?
  Devise.omniauth :openid_connect, {
    name: :oidc2,
    label: Rails.application.config.secrets.oidc2[:label],
    logo: Rails.application.config.secrets.oidc2[:logo],
    issuer: Rails.application.config.secrets.oidc2[:issuer],
    strategy_class: OmniAuth::Strategies::OpenIDConnect,
    scope: [:openid, :email, :profile],
    response_type: :code,
    discovery: true,
    client_options: {
      identifier: Rails.application.config.secrets.oidc2[:client_id],
      secret: Rails.application.config.secrets.oidc2[:secret],
      redirect_uri: Rails.application.config.secrets.oidc2[:redirect_uri].presence ||
        "#{TeSS::Config.base_url.chomp('/')}/users/auth/oidc2/callback"
    }
  }
end
