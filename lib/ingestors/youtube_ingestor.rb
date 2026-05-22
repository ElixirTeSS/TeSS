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

    def discover_feed_url(content, base_url)
      super_url = super(content, base_url) # discovers url from HTML
      return super_url if super_url

      # YouTube does not include feed URL of playlists in HTML
      uri = URI.parse(base_url)
      return nil unless Renderers::Youtube.is_youtube_url?(base_url)

      playlist_id = CGI.parse(uri.query.to_s).fetch('list', []).first
      return nil if playlist_id.blank?

      url = "https://www.youtube.com/feeds/videos.xml?playlist_id=#{CGI.escape(playlist_id)}"
      @messages << "Found Atom feed link from YouTube playlist URL, following: #{url}"
      url
    rescue URI::InvalidURIError
      nil
    end
  end
end
