require 'open-uri'
require 'json'
require 'redis'
require 'httparty'
require 'nokogiri'

module Ingestors
  # GithubIngestor fetches repository information from GitHub to populate the materials' metadata.
  # API requests counter:
  # 1. Get the repo's general metadata            #{GITHUB_API_BASE}/#{full_name}
  # 2. Get the doi                                #{GITHUB_API_BASE}/#{full_name}/contents/README.md
  # 3. Get the version/release                    #{GITHUB_API_BASE}/#{full_name}/releases
  # 4. Get the list of contributors               #{GITHUB_API_BASE}/#{full_name}/contributors
  # Searched keys:
  # api -> name, full_name, owner.login, html_url, description, homepage, topics, license.{key, spdx}, archived, created_at, pushed_at, updated_at, contributors_url,
  # doi -> content
  # version -> tag_name (first)
  # contributors -> login (from all entries)
  class GithubIngestor < Ingestor
    GITHUB_API_BASE = 'https://api.github.com/repos'.freeze
    GITHUB_COM_BASE = 'https://github.com'.freeze
    REDIS = Redis.new(url: TeSS::Config.redis_url)
    TTL_SEC = 30 * 24 * 60 * 60 # time to live in second after the cache is deleted

    def self.config
      {
        key: 'github',
        title: 'GitHub API',
        category: :materials,
        user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0'
      }
    end

    # Reads from direct GitHub URLs, .xml sitemaps, and .txt sitemaps.
    # Fetches repository metadata, contributors, releases, and DOIs (from CITATION.cff).
    # It handles automatically GitHub Pages URLs (github.io) and standard github.com URLs.
    # It caches API requests to avoid repeated calls.
    def read(source_url)
      @verbose = false
      sitemap_regex = /(github\.com|github\.io)/i
      # Returns either a map of unique URL entries, either the URL itself
      sources = if source_url.downcase.match?(/sitemap(.*)?.xml\Z/)
                  urls = SitemapParser.new(source_url, {
                    recurse: true,
                    url_regex: sitemap_regex,
                    headers: { 'User-Agent' => config[:user_agent] }
                  }).to_a.uniq.map(&:strip)
                  @messages << "Parsing .xml sitemap: #{source_url}\n - #{urls.count} URLs found"
                  urls
                elsif source_url.downcase.match?(/sitemap(.*)?.txt\Z/)
                  urls = open_url(source_url).to_a.uniq.map(&:strip)
                  @messages << "Parsing .txt sitemap: #{source_url}\n - #{urls.count} URLs found"
                  urls
                else
                  [source_url]
                end

      sources.each do |url|
        # Reads each source, if github.{com|io}, gets the repo's api, if not, next
        repo_api_url = to_github_api(url)
        next unless repo_api_url

        # Gets the cached repo data or reads and sets it
        repo_data = cache_or_set(repo_api_url.gsub(%r{https?://}, '').gsub('/', '_')) do
          content = open_url(repo_api_url)
          content ? JSON.parse(content.read) : nil
        end
        next unless repo_data

        # From the data, translate it to materials
        material = to_material(repo_data)

        # Add to material
        add_material material
      rescue StandardError => e
        @messages << "#{self.class.name} failed for #{url}, #{e.message}"
      end
    end

    private

    # Fetch cached data or opens webpage/api and cache it
    # I chose to cache because GitHub limmits up to 60 requests per hour for unauthenticated user
    # https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28#primary-rate-limit-for-unauthenticated-users
    # key: string key for the cache
    # ttl: time-to-live in seconds (default 30 days)
    def cache_or_set(key, ttl: TTL_SEC)
      Rails.logger.info "[Github Cache] GET cache #{key}"
      cached = REDIS.get(key)
      return JSON.parse(cached) if cached

      data = yield
      Rails.logger.info "[Github Cache] SET cache #{key}"
      REDIS.set(key, data.to_json, ex: ttl) if data
      data
    rescue StandardError => e
      warn "Cache fetch error: #{e.message}"
      yield
    end

    def to_github_api(url)
      uri = URI(url)
      return nil unless uri.host =~ /github\.com|github\.io/i

      if uri.host.end_with?('github.io')
        parts = uri.path.split('/')
        repo = parts[1]
        owner = uri.host.split('.').first
        github_api = "#{GITHUB_API_BASE}/#{owner}/#{repo}"
        return github_api
      elsif uri.host.end_with?('github.com')
        parts = uri.path.split('/')
        github_api = "#{GITHUB_API_BASE}/#{parts[1]}/#{parts[2]}"
        return github_api
      end
      nil
    end

    # Sets material hash keys and values and add them to material
    def to_material(repo_data)
      homepage_nil_or_empty = repo_data['homepage'].nil? || repo_data['homepage'].empty?
      url = homepage_nil_or_empty ? repo_data['html_url'] : get_redirected_url(repo_data['homepage']) # if no page, put github.com repo
      response = HTTParty.get(url, follow_redirects: true, headers: { 'User-Agent' => config[:user_agent] })
      doc = Nokogiri::HTML(response.body)

      material = OpenStruct.new
      material.title = repo_data['name'].titleize
      material.url = url
      material.description = homepage_nil_or_empty ? repo_data['description'] : fetch_definition(doc, url)
      material.keywords = repo_data['topics']
      material.licence = fetch_licence(repo_data['license'])
      material.status = repo_data['archived'] ? 'Archived' : 'Active'

      material.doi = fetch_doi(repo_data['full_name'])
      material.version = fetch_latest_release(repo_data['full_name'])
      material.date_created = repo_data['created_at']
      material.date_published = repo_data['pushed_at']
      material.date_modified = repo_data['updated_at']
      material.contributors = fetch_contributors(repo_data['contributors_url'])
      material.resource_type = homepage_nil_or_empty ? ['Github Repository'] : ['Github Page']
      material.prerequisites = fetch_prerequisites(doc)

      material
    end

    # URL – Some github homepages automatically redirects the user to another webpage
    # This method will get the last redirected URL (as shown by a 30X response or a `meta[http-equiv="Refresh"]` tag)
    def get_redirected_url(url, limit = 5)
      raise 'Too many redirects' if limit.zero?

      https_url = to_https(url) # some `homepage` were http
      response = HTTParty.get(https_url, follow_redirects: true, headers: { 'User-Agent' => config[:user_agent] })
      return https_url unless response.headers['content-type']&.include?('html')

      doc = Nokogiri::HTML(response.body)
      meta = doc.at('meta[http-equiv="Refresh"]')
      if meta && meta.to_s =~ /url=(.+)/i
        content = meta['content']
        relative_path = content[/url=(.+)/i, 1]
        base = https_url.end_with?('/') ? https_url : "#{https_url}/"
        escaped_path = URI::DEFAULT_PARSER.escape(relative_path).to_s
        new_url = "#{base}#{escaped_path}"
        return get_redirected_url(new_url, limit - 1)
      end
      https_url
    end

    def to_https(url)
      uri = URI.parse(url)
      uri.scheme = 'https'
      uri.to_s
    end

    # DEFINITION – Opens the GitHub homepage, fetches the 3 first >25 char <p> tags'text
    # and joins them with a 'Read more...' link at the end of the description
    # Some of the first <p> tags were not descriptive, thus skipping them
    def fetch_definition(doc, url)
      desc = ''
      round = 3
      doc.css('p').each do |p|
        p_txt = p&.text&.strip&.gsub(/\s+/, ' ')
        next if (p_txt.length < 25) || round.zero?

        desc = "#{desc}\n#{p_txt}"
        round -= 1
      end
      "#{desc}\n(...) [Read more...](#{url})"
    end

    # LICENCE – Get proper licence
    # the licence must match the format of config/dictionaries/licences.yml
    def fetch_licence(licence)
      return 'notspecified' if licence.nil? || licence == 'null'
      return 'other-at' if licence['key'] == 'other'

      licence['spdx_id']
    end

    # DOI – Fetches DOI from various sources in a repo
    # I chose to only read the `README.md` as it seems to have the DOI badge almost everytime.
    # Whereas enabling the fetching of CITATION.cff or CITATION.md would result in increasing
    # the number of api request.
    def fetch_doi(full_name)
      doi = fetch_doi_from_file(full_name, 'README.md')
      return doi if doi

      # doi = fetch_doi_from_file(full_name, 'CITATION.cff')
      # return doi if doi

      # doi = fetch_doi_from_file(full_name, 'CITATION.md')
      # return doi if doi
    rescue StandardError
      nil
    end

    # DOI – Fetches DOI from a specific file in repo (via GitHub API)
    def fetch_doi_from_file(full_name, filename)
      url = "#{GITHUB_API_BASE}/#{full_name}/contents/#{filename}"
      data = cache_or_set("doi_#{full_name.gsub('/', '_')}_#{filename.downcase}") do
        content = open_url(url)
        content ? JSON.parse(content.read) : nil
      end
      return nil unless data && data['content']

      decoded = Base64.decode64(data['content'])
      doi_match = decoded.match(/doi.org\/\s*([^\s,\)]+)/i)
      doi_match ? "https://doi.org/#{doi_match[1]}" : nil
    rescue StandardError
      nil
    end

    # RELEASE – Opens releases API address and returns last release
    def fetch_latest_release(full_name)
      url = "#{GITHUB_API_BASE}/#{full_name}/releases"
      releases = cache_or_set("releases_#{full_name.gsub('/', '_')}") do
        content = open_url(url)
        content ? JSON.parse(content.read) : nil
      end
      releases.is_a?(Array) && releases.first ? releases.first['tag_name'] : nil
    rescue StandardError
      nil
    end

    # CONTRIBUTORS – Opens contributors API address and returns list of contributors
    def fetch_contributors(contributors_url)
      contributors = cache_or_set("contributors_#{contributors_url.gsub(%r{https?://}, '').gsub('/', '_')}") do
        content = open_url(contributors_url)
        content ? JSON.parse(content.read) : nil
      end
      contributors.map { |c| (c['login']) }
    rescue StandardError
      nil
    end

    # PREREQUISITES – From the homepage HTML, looks for <p>'s ...
    def fetch_prerequisites(doc)
      prereq_paragraphs = []

      # ... after any heading tag (h1–h6) or span tag with text "prereq" (EN) or "prerreq" (ES)
      doc.xpath('//h1|//h2|//h3|//h4|//h5|//h6|//span').each do |h|
        next unless h.text =~ /prereq|prerreq/i # if prereq in text

        paras = h.xpath('following-sibling::*')
                 .take_while { |sib| %w[p ul ol].include?(sib.name) } # take either p, ul or ol
        prereq_paragraphs.concat(paras) if paras
      end

      # ... after any tag with id containing "prereq" (EN) or "prerreq" (ES)
      if prereq_paragraphs.empty?
        doc.xpath('//*[@id]').each do |node|
          next unless node['id'] =~ /prereq|prerreq/i || node['class'] =~ /prereq|prerreq/i # if prereq in id or class

          paras = node.xpath('following-sibling::*')
                      .take_while { |sib| %w[p ul ol].include?(sib.name) } # take either p, ul or ol
          prereq_paragraphs.concat(paras) if paras

          next unless prereq_paragraphs.empty? # else

          paras = node.xpath('.//p | .//ul | .//ol') # get all <p>, <ul>, <ol> inside this node – more 'destructive'
          prereq_paragraphs.concat(paras) if paras.any?
        end
      end

      prereq_paragraphs&.join("\n")&.gsub(/\n\n+/, "\n")&.to_s&.strip
    end
  end
end
