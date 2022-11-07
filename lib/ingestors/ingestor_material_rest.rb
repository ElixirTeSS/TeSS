require 'rest-client'
require 'json'

module Ingestors
  class IngestorMaterialRest < IngestorMaterial
    def initialize
      super
    end

    def read(url)
      # paged query
      next_page = url

      begin
        # process each page
        until next_page.nil?
          response = RestClient::Request.new(method: :get, url: CGI.unescape_html(next_page), verify_ssl: false).execute
          if response.code == 200
            # format response
            results = JSON.parse(response.to_str)

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
        material = Material.new
        material.status = 'active'
        material.doi = input['doi'] unless metadata['doi'].nil?
        material.authors = []
        material.contributors = []
        unless metadata.nil?
          material.title = metadata['title'] unless metadata['title'].nil?
          material.description = process_description metadata['description']
          material.keywords = metadata['keywords'] unless metadata['keywords'].nil?
          material.licence = metadata['license']['id'] unless metadata['license'].nil? or metadata['license']['id'].nil?
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
        material.url = links['html'] if !links.nil? && !links['html'].nil?

        # add material to array
        add_material material
        @ingested += 1
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
