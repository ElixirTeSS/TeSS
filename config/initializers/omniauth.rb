Rails.application.config.middleware.use OmniAuth::Builder do
  OmniAuth.config.allowed_request_methods = [:post]

  OmniAuth.config.request_validation_phase = Rails.env.test? ? nil : OmniAuth::AuthenticityTokenProtection.new(key: :_csrf_token)
end

