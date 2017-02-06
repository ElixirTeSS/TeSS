Recaptcha.configure do |config|
  config.site_key  = TeSS::Config.recaptcha['sitekey']
  config.secret_key  = TeSS::Config.recaptcha['secret']
end
