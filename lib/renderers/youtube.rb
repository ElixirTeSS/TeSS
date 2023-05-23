# frozen_string_literal: true

module Renderers
  class Youtube
    VALID_HOSTS = %w[youtube.com youtu.be m.youtube.com www.youtube.com].freeze
    VALID_SCHEMES = %w[http https].freeze
    TEMPLATE = %(<iframe width="560" height="315" src="https://www.youtube.com/embed/%{code}" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>)

    def initialize(resource)
      @resource = resource
    end

    def can_render?
      @resource.url && extract_video_code(@resource.url)
    end

    def render_content
      code = extract_video_code(@resource.url)
      format(TEMPLATE, code: code).html_safe
    end

    def extract_video_code(url)
      return unless is_youtube_url?(url)

      match = url.match(/[?&]vi?=([-_a-zA-Z0-9]+)/) ||
              url.match(%r{youtu\.be/([-_a-zA-Z0-9]+)}) ||
              url.match(%r{/v/([-_a-zA-Z0-9]+)}) ||
              url.match(%r{/embed/([-_a-zA-Z0-9]+)})
      match[1] if match
    end

    private

    def is_youtube_url?(url)
      parsed_url = URI.parse(url)
      VALID_HOSTS.include?(parsed_url.host) && VALID_SCHEMES.include?(parsed_url.scheme)
    rescue StandardError
      false
    end
  end
end
