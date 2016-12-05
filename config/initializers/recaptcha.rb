Recaptcha.configure do |config|
  config.site_key  = Rails.application.secrets.captcha_sitekey
  config.secret_key  = Rails.application.secrets.captcha_secret
end
