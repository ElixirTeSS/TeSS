Recaptcha.configure do |config|
  config.site_key  = Rails.application.config.secrets.recaptcha[:sitekey]
  config.secret_key  = Rails.application.config.secrets.recaptcha[:secret]
end
