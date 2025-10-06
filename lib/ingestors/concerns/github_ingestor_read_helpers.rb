# frozen_string_literal: true

module Ingestors
  module Concerns
    # This module is to change the github.{com|io} to api.github.com
    module GithubIngestorReadHelpers
      private

      # Takes a github.{com|io} url and returns its api.google.com url
      def to_github_api(url)
        uri = URI(url)
        return nil unless uri.host =~ /github\.com|github\.io/i

        if uri.host.end_with?('github.io')
          github_api_from_io(uri)
        elsif uri.host.end_with?('github.com')
          github_api_from_com(uri)
        end
      end

      def github_host?(host)
        host =~ /github\.com|github\.io/i
      end

      def github_api_from_io(uri)
        parts = uri.path.split('/')
        repo  = parts[1]
        owner = uri.host.split('.').first
        "#{GITHUB_API_BASE}/#{owner}/#{repo}"
      end

      def github_api_from_com(uri)
        parts = uri.path.split('/')
        "#{GITHUB_API_BASE}/#{parts[1]}/#{parts[2]}"
      end
    end
  end
end
