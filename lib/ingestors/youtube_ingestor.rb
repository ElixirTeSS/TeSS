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
      url = super(content, base_url)
      return url if url.present?

      uri = URI.parse(base_url)
      return nil unless Renderers::Youtube.is_youtube_url?(base_url)

      playlist_id = CGI.parse(uri.query.to_s).fetch('list', []).first
      return nil if playlist_id.blank?

      playlist_feed_url = "https://www.youtube.com/feeds/videos.xml?playlist_id=#{CGI.escape(playlist_id)}"
      @messages << "Found Atom feed link from YouTube playlist URL, following: #{playlist_feed_url}" if playlist_feed_url.present?
      playlist_feed_url
    rescue URI::InvalidURIError
      nil
    end
  end
end
