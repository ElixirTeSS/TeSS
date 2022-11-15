module Renderers
  class Youtube
    TEMPLATE = %(<iframe width="560" height="315" src="https://www.youtube.com/embed/%{code}" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>)

    def initialize(resource)
      @resource = resource
    end

    def can_render?
      @resource.url && extract_video_code(@resource.url)
    end

    def render_content
      code = extract_video_code(@resource.url)
      (TEMPLATE % { code: code }).html_safe
    end

    def extract_video_code(url)
      return unless is_youtube_url?(url)

      match = url.match(/[\?\&]v?\=([-_a-zA-Z0-9]+)/) ||
        url.match(/[\?\&]vi?\=([-_a-zA-Z0-9]+)/) ||
        url.match(/youtu\.be\/([-_a-zA-Z0-9]+)/) ||
        url.match(/\/v\/([-_a-zA-Z0-9]+)/) ||
        url.match(/\/embed\/([-_a-zA-Z0-9]+)/)
      match[1] if match
    end

    private

    def is_youtube_url?(url)
      parsed_url = URI.parse(url)
      parsed_url.host.end_with?('youtube.com', 'youtu.be') && parsed_url.scheme =~ /(http|https)/
    rescue
      false
    end
  end
end