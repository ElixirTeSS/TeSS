# EGI Check-in OpenID Connect configuration
unless Rails.application.config.secrets.dig(:egi, :client_id).blank?
  egi_secrets = Rails.application.config.secrets.egi

  # Discovery needs the issuer; without it OmniAuth fails with a misleading "tcp connection to https:443" error.
  if egi_secrets[:issuer].blank?
    Rails.logger.warn('EGI Check-in: egi.client_id is set but egi.issuer is empty in secrets.yml, provider not registered')
    return
  end

  redirect_uri = egi_secrets[:redirect_uri].presence ||
                 "#{TeSS::Config.base_url.chomp('/')}/users/auth/egi/callback"

  Devise.omniauth :openid_connect, {
    name: :egi,
    logo: 'egi/EGI_small.png',
    logo_with_label: true,
    button_class: 'btn-primary',
    redirect_uris: [redirect_uri],
    scope: %w[openid profile email entitlements],
    response_type: :code,
    issuer: egi_secrets[:issuer],
    discovery: true,
    client_options: {
      identifier: egi_secrets[:client_id],
      secret: egi_secrets[:secret],
      redirect_uri: redirect_uri
    }
  }
end
