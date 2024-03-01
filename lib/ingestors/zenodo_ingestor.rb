require 'rest-client'
require 'json'

module Ingestors
  class ZenodoIngestor < Ingestor
    def self.config
      {
        key: 'zenodo',
        title: 'Zenodo API',
        category: :materials
      }
    end

    def read(url)
      # paged query
      next_page = url

      begin
        # process each page
        until next_page.nil?
          content = open_url(CGI.unescape_html(next_page))

          if content
            # format response
            results = JSON.parse(content.read)

            # extract materials from results
            unless results['hits'].nil? and results['hits']['hits'].nil?
              hits = results['hits']['hits']
              hits.each do |item|
                process_material item
              end
            end
          else
            next_page = nil
          end

          # set next page
          old_page = next_page
          next_page = results['links']['next'] unless results['links'].nil? or results['links']['next'].nil?
          next_page = nil if next_page == old_page
        end
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_material(input)
      # map top-level tags
      metadata = input['metadata']
      links = input['links']

      # copy values
      begin
        material = OpenStruct.new
        material.status = 'active'
        material.doi = input['doi'] unless metadata['doi'].nil?
        material.authors = []
        material.contributors = []
        unless metadata.nil?
          material.title = metadata['title'] unless metadata['title'].nil?
          material.description = process_description metadata['description']
          material.keywords = metadata['keywords'] unless metadata['keywords'].nil?
          material.licence = metadata['license']['id'].upcase unless metadata.dig('license', 'id').nil?
          unless metadata['creators'].nil?
            metadata['creators'].each do |c|
              entry = c['orcid'].nil? ? c['name'] : "#{c['name']} (orcid: #{c['orcid']})"
              material.authors << entry
            end
          end
          unless metadata['contributors'].nil?
            metadata['contributors'].each do |c|
              entry = c['type'].nil? ? c['name'] : "#{c['name']} (type: #{c['type']})"
              material.contributors << entry
            end
          end

        end
        material.url = links['self_html'] if !links.nil? && !links['self_html'].nil?

        # add material to array
        add_material material
      rescue Exception => e
        @messages << "#{self.class.name} extract material fields failed with: #{e.message}"
      end

      # finished
      nil
    end

    def process_description(input)
      return nil if input.nil?

      input = CGI.unescape(input)
      convert_description(input)
    end
  end
end
