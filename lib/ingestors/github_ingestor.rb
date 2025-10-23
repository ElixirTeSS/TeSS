# frozen_string_literal: true

require 'open-uri'
require 'json'
require 'httparty'
require 'nokogiri'

module Ingestors
  # GithubIngestor fetches repository information from GitHub to populate the materials' metadata.
  # API requests counter:
  # 1. Get the repo's general metadata            #{GITHUB_API_BASE}/#{full_name}
  #    and keys:                                  name, full_name, owner.login, html_url, description,
  #                                               homepage, topics, license.{key, spdx}, archived,
  #                                               created_at, pushed_at, updated_at, contributors_url
  # 2. Get the doi                                #{GITHUB_API_BASE}/#{full_name}/contents/README.md
  #    and key:                                   content
  # 3. Get the version/release                    #{GITHUB_API_BASE}/#{full_name}/releases
  #    and key:                                   tag_name (first)
  # 4. Get the contributors' list                 #{GITHUB_API_BASE}/#{full_name}/contributors
  #    and key:                                   login (from all entries)
  class GithubIngestor < Ingestor # rubocop:disable Metrics/ClassLength
    include Ingestors::Concerns::SitemapHelpers

    GITHUB_API_BASE = 'https://api.github.com/repos'
    CACHE_PREFIX = 'github_ingestor_'
    TTL = 1.week # time to live after the cache is deleted

    def self.config
      {
        key: 'github',
        title: 'GitHub Repository or Page',
        category: :materials,
        user_agent: 'TeSS Github ingestor'
      }
    end

    # Reads from direct GitHub URLs, .xml sitemaps, and .txt sitemaps.
    # Fetches repository metadata, contributors, releases, and DOIs (from CITATION.cff).
    # It handles automatically GitHub Pages URLs (github.io) and standard github.com URLs.
    # It caches API requests to avoid repeated calls.
    def read(source_url)
      @verbose = false
      # Returns either a map of unique URL entries, either the URL itself
      sources = get_sources(source_url)

      sources.each do |url|
        # Reads each source, if github.{com|io}, gets the repo's api, if not, next
        repo_api_url = to_github_api(url)
        next unless repo_api_url

        # Gets the cached repo data or reads and sets it
        key = "#{CACHE_PREFIX}#{repo_api_url.gsub(%r{https?://}, '').gsub('/', '_')}"
        repo_data = get_or_set_cache(key, repo_api_url)
        next unless repo_data

        # Add to material
        add_material to_material(repo_data)
      end
    rescue StandardError => e
      @messages << "#{self.class.name} read failed, #{e.message}"
    end

    private

    # Takes a github.{com|io} url and returns its api.google.com url
    def to_github_api(url)
      uri = URI(url)
      return nil unless uri.host =~ /(\.|\A)(github\.com|github\.io)\Z/i

      if uri.host.end_with?('github.io')
        github_api_from_io(uri)
      elsif uri.host.end_with?('github.com')
        github_api_from_com(uri)
      end
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

    # Fetch cached data or opens webpage/api and cache it
    # I chose to cache because GitHub limits up to 60 requests per hour for unauthenticated user
    # https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28#primary-rate-limit-for-unauthenticated-users
    # One GitHub URL equals to 4 GitHub API requests.
    # key: string key for the cache
    # ttl: time-to-live in seconds (default 7 days)
    def get_or_set_cache(key, url)
      Rails.cache.fetch(key, expires_in: TTL) do
        JSON.parse(open_url(url).read)
      end
    rescue StandardError => e
      @messages << "#{self.class.name} get_or_set_cache failed for #{url}, #{e.message}"
      yield if block_given?
      nil
    end

    # Sets material hash keys and values and add them to material
    def to_material(repo_data) # rubocop:disable Metrics/AbcSize
      homepage_nil_or_empty = nil_or_empty? repo_data['homepage']
      url = homepage_nil_or_empty ? repo_data['html_url'] : repo_data['homepage']
      redirected_url = get_redirected_url(url)
      doc = fetch_homepage_doc(redirected_url)

      material = OpenStruct.new
      material.title = repo_data['name'].titleize
      material.url = url
      material.description = homepage_nil_or_empty ? repo_data['description'] : fetch_definition(doc, redirected_url)
      material.keywords = repo_data['topics']
      material.licence = fetch_licence(repo_data['license'])
      material.status = repo_data['archived'] ? 'Archived' : 'Active'
      material.doi = fetch_doi(repo_data['full_name'])
      material.version = fetch_latest_release(repo_data['full_name'])
      material.date_created = repo_data['created_at']
      material.date_published = repo_data['pushed_at']
      material.date_modified = repo_data['updated_at']
      material.contributors = fetch_contributors(repo_data['contributors_url'], repo_data['full_name'])
      material.resource_type = homepage_nil_or_empty ? ['Github Repository'] : ['Github Page']
      material.prerequisites = fetch_prerequisites(doc)
      material
    end

    def nil_or_empty?(repo_data)
      repo_data.nil? || repo_data.empty?
    end

    def fetch_homepage_doc(url)
      response = HTTParty.get(url, follow_redirects: true, headers: { 'User-Agent' => config[:user_agent] })
      Nokogiri::HTML(response.body)
    end

    # DEFINITION – Opens the GitHub homepage, fetches the 3 first >25 char <p> tags'text
    # and joins them with a 'Read more...' link at the end of the description
    # Some of the first <p> tags were not descriptive, thus skipping them
    def fetch_definition(doc, url)
      desc = ''
      round = 3
      doc.css('p').each do |p|
        p_txt = p&.text&.strip&.gsub(/\s+/, ' ')
        next if (p_txt.length < 50) || round.zero?

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
      filename = 'README.md'
      url = "#{GITHUB_API_BASE}/#{full_name}/contents/#{filename}"
      data = get_or_set_cache("#{CACHE_PREFIX}doi_#{full_name.gsub('/', '_')}_#{filename.downcase}", url)
      return nil unless data && data['content']

      decoded = Base64.decode64(data['content'])
      doi_match = decoded.match(%r{doi.org/\s*([^\s,)]+)}i)
      doi_match ? "https://doi.org/#{doi_match[1]}" : nil
    rescue StandardError => e
      @messages << "#{self.class.name} fetch_doi failed for #{url}, #{e.message}"
    end

    # RELEASE – Opens releases API address and returns last release
    def fetch_latest_release(full_name)
      url = "#{GITHUB_API_BASE}/#{full_name}/releases"
      releases = get_or_set_cache("#{CACHE_PREFIX}releases_#{full_name.gsub('/', '_')}", url)
      releases.is_a?(Array) && releases.first ? releases.first['tag_name'] : nil
    rescue StandardError => e
      @messages << "#{self.class.name} fetch_latest_release failed for #{url}, #{e.message}"
    end

    # CONTRIBUTORS – Opens contributors API address and returns list of contributors
    def fetch_contributors(contributors_url, full_name)
      contributors = get_or_set_cache("#{CACHE_PREFIX}contributors_#{full_name.gsub('/', '_')}", contributors_url)
      contributors.map { |c| (c['login']) }
    rescue StandardError => e
      @messages << "#{self.class.name} fetch_contributors failed for #{contributors_url}, #{e.message}"
    end

    # PREREQUISITES – From the homepage HTML, looks for <p> tags which are children of ...
    def fetch_prerequisites(doc)
      prereq_paragraphs = []

      # ... any heading tag (h1–h6) or span tag with text "prereq" (EN) or "prerreq" (ES)
      prereq_paragraphs = fetch_prerequisites_from_h(doc, prereq_paragraphs)

      # ... any tag with id containing "prereq" (EN) or "prerreq" (ES)
      prereq_paragraphs = fetch_prerequisites_from_id_or_class(doc, prereq_paragraphs) if prereq_paragraphs.empty?

      prereq_paragraphs&.join("\n")&.gsub(/\n\n+/, "\n")&.to_s&.strip
    end

    def fetch_prerequisites_from_h(doc, prereq_paragraphs)
      doc.xpath('//h1|//h2|//h3|//h4|//h5|//h6|//span').each do |h|
        next unless h.text =~ /prereq|prerreq/i # if prereq in text

        paragraph = h.xpath('following-sibling::*')
                     .take_while { |sib| %w[p ul ol].include?(sib.name) } # take either p, ul or ol
        prereq_paragraphs.concat(paragraph) if paragraph
      end
      prereq_paragraphs
    end

    def fetch_prerequisites_from_id_or_class(doc, prereq_paragraphs)
      doc.xpath('//*[@id]').each do |node|
        next unless prereq_node?(node)

        extract_following_paragraphs(node, prereq_paragraphs)
        extract_nested_paragraphs(node, prereq_paragraphs) if prereq_paragraphs.empty?
      end
      prereq_paragraphs
    end

    def prereq_node?(node)
      [node['id'], node['class']].compact.any? { |attr| attr =~ /prereq|prerreq/i }
    end

    def extract_following_paragraphs(node, prereq_paragraphs)
      paragraphs = node.xpath('following-sibling::*')
                       .take_while { |sib| %w[p ul ol].include?(sib.name) }
      prereq_paragraphs.concat(paragraphs) if paragraphs
    end

    def extract_nested_paragraphs(node, prereq_paragraphs)
      paragraphs = node.xpath('.//p | .//ul | .//ol')
      prereq_paragraphs.concat(paragraphs) if paragraphs.any?
    end
  end
end
