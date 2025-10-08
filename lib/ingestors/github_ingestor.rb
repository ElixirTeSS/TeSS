# frozen_string_literal: true

require 'open-uri'
require 'json'
require 'httparty'
require 'nokogiri'

module Ingestors
  GITHUB_API_BASE = 'https://api.github.com/repos'
  GITHUB_COM_BASE = 'https://github.com'
  TTL = 1.week # time to live after the cache is deleted

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
  class GithubIngestor < Ingestor
    include Ingestors::Concerns::SitemapHelpers
    include Ingestors::Concerns::GithubIngestorReadHelpers
    include Ingestors::Concerns::GithubIngestorMaterialHelpers

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
      # Returns either a map of unique URL entries, either the URL itself
      sources = get_sources(source_url)

      sources.each do |url|
        # Reads each source, if github.{com|io}, gets the repo's api, if not, next
        repo_api_url = to_github_api(url)
        next unless repo_api_url

        # Gets the cached repo data or reads and sets it
        key = repo_api_url.gsub(%r{https?://}, '').gsub('/', '_')
        repo_data = get_or_set_cache(key, repo_api_url)
        next unless repo_data

        # Add to material
        add_material to_material(repo_data)
      rescue StandardError => e
        @messages << "#{self.class.name} failed for #{url}, #{e.message}"
      end
    end

    private

    # Sets material hash keys and values and add them to material
    def to_material(repo_data) # rubocop:disable Metrics/AbcSize
      url, homepage_nil_or_empty = resolve_url(repo_data)

      doc = fetch_homepage_doc(url)

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

    # Fetch cached data or opens webpage/api and cache it
    # I chose to cache because GitHub limits up to 60 requests per hour for unauthenticated user
    # https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28#primary-rate-limit-for-unauthenticated-users
    # One GitHub URL equals to 4 GitHub API requests.
    # key: string key for the cache
    # ttl: time-to-live in seconds (default 7 days)
    def get_or_set_cache(key, url)
      content = open_url(url)
      data = content ? JSON.parse(content.read) : nil

      set_cache(key, data) if Rails.cache.read(key).nil? # sets cache only if there is no cache yet or is expired
      get_cache(key)
      data
    rescue StandardError => e
      warn "Cache fetch error: #{e.message}"
      yield
    end

    def set_cache(key, data, ttl: TTL)
      Rails.logger.info "[Github Cache] SET cache #{key}"
      Rails.cache.write(key, data, expires_in: ttl) unless data.nil?
    end

    def get_cache(key)
      Rails.logger.info "[Github Cache] GET cache #{key}"
      Rails.cache.read(key)
    end
  end
end
