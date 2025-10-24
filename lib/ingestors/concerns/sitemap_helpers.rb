# frozen_string_literal: true

module Ingestors
  module Concerns
    # From a sitemap.{xml|txt} or a single URL, get the list of URLs (= sources)
    module SitemapHelpers
      private

      def get_sources(source_url)
        case source_url.downcase
        when /sitemap(.*)?\.xml\Z/
          parse_xml_sitemap(source_url)
        when /sitemap(.*)?\.txt\Z/
          parse_txt_sitemap(source_url)
        else
          [source_url]
        end
      end

      def parse_xml_sitemap(url)
        urls = SitemapParser.new(
          url,
          recurse: true,
          headers: { 'User-Agent' => config[:user_agent] }
        ).to_a.uniq.map(&:strip)

        log_sitemap('xml', url, urls.count)
        urls
      end

      def parse_txt_sitemap(url)
        urls = open_url(url).to_a.uniq.map(&:strip)

        log_sitemap('txt', url, urls.count)
        urls
      end

      def log_sitemap(ext, url, count)
        @messages << "Parsing .#{ext} sitemap: #{url}\n - #{count} URLs found"
      end
    end
  end
end
