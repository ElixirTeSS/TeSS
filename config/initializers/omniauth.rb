require 'request_forgery_protection_token_verifier'

Rails.application.config.middleware.use OmniAuth::Builder do
  OmniAuth.config.allowed_request_methods = [:post]
  OmniAuth.config.before_request_phase = RequestForgeryProtectionTokenVerifier.new
end
