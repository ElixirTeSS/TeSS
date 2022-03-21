require 'ingestors/ingestor_material'
require 'rest-client'
require 'json'

class IngestorMaterialRest < IngestorMaterial

  def initialize
    super
  end

  def read (url)
    processed = 0
    messages = []

    # paged query
    next_page = url

    begin
      # process each page
      while !next_page.nil?
        response = RestClient::Request.new(method: :get, url: CGI.unescape_html(next_page), verify_ssl: false).execute
        if response.code == 200
          # format response
          results = JSON.parse(response.to_str)

          # extract materials from results
          unless results['hits'].nil? and results['hits']['hits'].nil?
            hits = results['hits']['hits']
            hits.each do |item|
              mats_processed, mats_messages = process_material item
              processed += mats_processed
              messages += mats_messages
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
      messages << "#{self.class.name} failed with: #{e.message}"
    end

    # finished
    return processed, messages
  end

  def process_material(input)
    processed = 0
    messages = []

    # map top-level tags
    metadata = input['metadata']
    links = input['links']

    # copy values
    begin
      material = Material.new
      material.status = 'active'
      material.doi = input['doi'] unless  metadata['doi'].nil?
      material.authors = []
      material.contributors = []
      unless metadata.nil?
        material.title = metadata['title'] unless metadata['title'].nil?
        material.description = CGI.unescape(metadata['description']) unless metadata['description'].nil?
        material.keywords = metadata['keywords'] unless metadata['keywords'].nil?
        material.licence = metadata['license']['id'] unless metadata['license'].nil? or metadata['license']['id'].nil?
        unless metadata['creators'].nil?
          metadata['creators'].each do |c|
            c['orcid'].nil? ? entry = c['name'] : entry = "#{c['name']} (orcid: #{c['orcid']})"
            material.authors << entry
          end
        end
        unless metadata['contributors'].nil?
          metadata['contributors'].each do |c|
            c['type'].nil? ? entry = c['name'] : entry = "#{c['name']} (type: #{c['type']})"
            material.contributors << entry
          end
        end

      end
      if !links.nil?
        material.url = links['html'] unless links['html'].nil?
      end

      # add material to array
      add_material(material)
      processed += 1
    rescue Exception => e
      messages << "#{self.class.name} extract material fields failed with: #{e.message}"
    end

    # finished
    return processed, messages
  end


end