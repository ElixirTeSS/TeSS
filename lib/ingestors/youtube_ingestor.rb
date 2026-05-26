module Ingestors
  class YoutubeIngestor < MaterialRSSIngestor
    require 'cgi'

    def self.config
      {
        key: 'youtube',
        title: 'YouTube',
        category: :materials
      }
    end

    private

    def discover_feed_url(content, base_url)
      super(content, base_url)

      return unless (url = discover_feed_url_from_youtube_playlist_url(base_url))

      @messages << "Found Atom feed link from YouTube playlist URL, following: #{url}"
      url
    end

    def discover_feed_url_from_youtube_playlist_url(base_url)
      uri = URI.parse(base_url)
      return nil unless Renderers::Youtube.is_youtube_url?(base_url)

      playlist_id = CGI.parse(uri.query.to_s).fetch('list', []).first
      return nil if playlist_id.blank?

      "https://www.youtube.com/feeds/videos.xml?playlist_id=#{CGI.escape(playlist_id)}"
    rescue URI::InvalidURIError
      nil
    end
  end
end
