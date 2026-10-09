module TessOmniauthRedirectUris
  module_function

  def valid_login_domain?(space_host, login_host)
    return false if space_host.blank? || login_host.blank?

    own_domain = PublicSuffix.domain(space_host)
    target_domain = PublicSuffix.domain(login_host)

    return space_host == login_host if own_domain.nil? || target_domain.nil?

    own_domain == target_domain
  end

  def resolve_for_host(redirect_uris, host)
    uris = Array(redirect_uris)
    uris.find { |uri| valid_login_domain?(URI.parse(uri).host, host) } || uris.first
  end
end

module OmniAuth
  module Strategies
    class HostRedirectOpenIDConnect < OpenIDConnect
      option :redirect_uris, []

      def redirect_uri
        resolved_uri = TessOmniauthRedirectUris.resolve_for_host(options[:redirect_uris], request&.host)

        return super unless resolved_uri.present?

        # preserve params['redirect_uri'] behavior from OpenIDConnect strategy
        return resolved_uri unless params['redirect_uri']

        "#{resolved_uri}?redirect_uri=#{CGI.escape(params['redirect_uri'])}"
      end
    end
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  OmniAuth.config.allowed_request_methods = [:post]

  OmniAuth.config.request_validation_phase = Rails.env.test? ? nil : OmniAuth::AuthenticityTokenProtection.new(key: :_csrf_token)
end

