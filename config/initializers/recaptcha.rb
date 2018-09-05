Recaptcha.configure do |config|
  config.site_key  = Rails.application.secrets.recaptcha[:sitekey]
  config.secret_key  = Rails.application.secrets.recaptcha[:secret]
end
