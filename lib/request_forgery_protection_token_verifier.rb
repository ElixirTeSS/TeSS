# frozen_string_literal: true

# Provides a callable method that verifies Cross-Site Request Forgery protection
# token. This class includes `ActionController::RequestForgeryProtection`
# directly and utilizes `verified_request?` method to match the way Rails
# performs token verification in Rails controllers.
#
# If you like to learn more about how Rails generate and verify authenticity
# token, you can find the source code at
# https://github.com/rails/rails/blob/v5.2.2/actionpack/lib/action_controller/metal/request_forgery_protection.rb#L217-L240.
class RequestForgeryProtectionTokenVerifier
  include ActiveSupport::Configurable
  include ActionController::RequestForgeryProtection

  # `ActionController::RequestForgeryProtection` contains a few configurable
  # options. As we want to make sure that our configuration is the same as what
  # being set in `ActionController::Base`, we should make all out configuration
  # methods to delegate to `ActionController::Base`.
  config.each_key do |configuration_name|
    define_method configuration_name do
      ActionController::Base.config[configuration_name]
    end
  end

  def call(env)
    @request = ActionDispatch::Request.new(env)

    raise ActionController::InvalidAuthenticityToken unless verified_request?
  end

  private

  attr_reader :request

  delegate :params, :session, to: :request
end
