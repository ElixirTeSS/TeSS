module OmniAuth
  module Strategies
    class HostRedirectOpenIDConnect < OpenIDConnect
      option :extra_redirect_uris, []

      def redirect_uri
        default_redirect_uri = options.dig(:client_options, :redirect_uri)
        extra_redirect_uris = Array(options[:extra_redirect_uris])
        redirect_uris = [default_redirect_uri, *extra_redirect_uris].compact_blank

        resolved_uri = redirect_uris.find do |uri|
          URI.parse(uri).host == request&.host
        rescue URI::InvalidURIError
          false
        end || default_redirect_uri

        return super unless resolved_uri.present?

        # preserve params['redirect_uri'] behavior from OpenIDConnect strategy
        return resolved_uri unless params['redirect_uri']

        "#{resolved_uri}?redirect_uri=#{CGI.escape(params['redirect_uri'])}"
      end
    end
  end
end