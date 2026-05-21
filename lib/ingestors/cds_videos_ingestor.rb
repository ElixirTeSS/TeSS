# frozen_string_literal: true
require 'json'
require 'httparty'
require 'nokogiri'

module Ingestors
  class CdsVideosIngestor < Ingestor # rubocop:disable Style/Documentation
    CDS_VIDEOS_RECORD_URL = 'https://videos.cern.ch/record/'

    def self.config
      {
        key: 'cds videos',
        title: 'CDS videos record or search',
        category: :materials,
        user_agent: 'TeSS CDS Videos ingestor'
      }
    end

    # Reads from single CDS record URL or search query URL
    # For a search query, we need to change fields: page to 1 and size to 100
    # Then read all pages while running `to_material()`
    # Else for a single material, go direct with `to_material()`
    def read(source_url)
      @verbose = false

      api_url = to_api(source_url)

      if source_url.include?('search')
        api_url_page_updated = update_url_field_value(api_url, 'page', 1)
        api_url_page_size_updated = update_url_field_value(api_url_page_updated, 'size', 100)
        data = JSON.parse(open_url(api_url_page_size_updated).read)
        add_records_material(data)
      else
        data = JSON.parse(open_url(api_url).read)
        add_material to_material(data)
      end
    rescue StandardError => e
      Rails.logger.error("#{e.class}: read() failed, #{e.message}")
    end

    private

    def to_api(url)
      uri = URI(url)
      parts = uri.path.split('/') # 'example.com/foo/bar' will have path == '/foo/bar', so three parts

      # FROM '/search?{query}'
      if parts[1] == 'search' && parts.size == 2
        # TO '/api/records/{query}'
        "https://#{uri.host}/api/records?#{uri.query}"
      # FROM '/record/{recid}'
      elsif parts[1] == 'record' && parts.size == 3
        # TO 'api/record/{recid}'
        "https://#{uri.host}/api/#{parts[1]}/#{parts[2]}"
      end
    end

    def update_url_field_value(url, field, value)
      uri = URI.parse(url)
      params = URI.decode_www_form(uri.query || '').to_h
      params[field] = value.to_s
      uri.query = URI.encode_www_form(params)
      uri.to_s
    end

    def add_records_material(initial_data)
      data = initial_data

      while data
        hits = data.dig('hits', 'hits') || []
        hits.each { |hit| add_material to_material(hit) }

        next_url = data.dig('links', 'next')
        break unless next_url

        response = open_url(next_url)&.read
        data = response ? JSON.parse(response) : nil
      end
    end

    # Sets material hash keys and values and add them to material
    def to_material(data)
      metadata = data['metadata']&.transform_keys! { |k| k == '_cds' ? 'cds' : k }

      material = OpenStruct.new
      material.title = metadata.dig('title', 'title').titleize
      material.url = "#{CDS_VIDEOS_RECORD_URL}#{data['id']}"
      material.description = get_description(metadata)
      material.keywords = metadata['keywords'][0..9]&.map { |k| k['name'] }&.join(', ') || ''
      material.licence = metadata.dig('copyright', 'holder') == 'CERN' ? 'other-at' : 'notspecified'
      material.status = 'Active'
      material.contact = get_contact(metadata)
      material.version = metadata['report_number'][0]
      material.date_created = metadata['date']
      material.date_published = metadata['publication_date']
      material.authors = get_authors(metadata)
      material.contributors = get_contributors(metadata)
      material.resource_type = "#{metadata['type'].titleize} – #{metadata['category'].titleize}"
      material
    end

    def get_description(metadata)
      description = metadata['description'].split('<br>')[0] + "\n\n"
      description = description&.<< "Video duration: #{metadata['duration']}\n\n" if metadata['duration']
      description = description + metadata['additional_descriptions']&.map { |k| k['description'] }&.join("\n\n") + "\n\n" || '' if metadata['additional_descriptions']
      description = description&.<< "Related identifier:\n- Is part of: #{metadata['alternate_identifiers'][0]['value']} (URL)\n\n" if metadata['alternate_identifiers']&.any?
      description = description&.<< "Copyright: [#{metadata.dig('copyright', 'holder')}](#{metadata.dig('copyright', 'url')}) (#{metadata.dig('copyright', 'year')})" if metadata.dig('copyright', 'holder')
      description
    end

    def get_authors(metadata)
      metadata['contributors']
            &.select { |c| c['role'] == 'Creator' }
            &.reject { |c| c['name'].downcase == 'cern' }
            &.map { |c| c['name']&.gsub(',', '')&.titleize } || ''
    end

    def get_contributors(metadata)
      metadata['contributors']
            &.reject { |c| c['role'] == 'Creator' || c['role'] == 'ContactPerson' }
            &.reject { |c| c['name'].downcase == 'cern' }
            &.map { |c| c['name']&.gsub(',', '')&.titleize } || ''
    end

    def get_contact(metadata)
      contributors = metadata['contributors'] || []

      # 1. Check for ContactPerson name
      contact_person = contributors.find { |c| c['role'] == 'ContactPerson' }
      contact_name = contact_person&.[]('name')&.gsub(',', '')&.titleize

      # 2. Check for Creator email
      creator = contributors.find { |c| c['role'] == 'Creator' }
      creator_email = creator&.[]('email')&.gsub(',', '')&.titleize

      # 3. Check for any other contributor email
      other_contributor = contributors.find { |c| !%w[ContactPerson Creator].include?(c['role']) }
      other_email = other_contributor&.[]('email')

      contact_name.presence || creator_email.presence || other_email || ''
    end
  end
end
