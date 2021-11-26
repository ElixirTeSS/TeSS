require 'ingestors/ingestor_material'
require 'rest-client'
require 'json'

class IngestorMaterialRest < IngestorMaterial

  def initialize
    super
  end

  def read (url)
    processed = 0

    # paged query
    next_page = url

    begin

      while !next_page.nil?

        #puts "next_page = " + CGI.unescape_html(next_page).inspect
        response = RestClient::Request.new(method: :get, url: CGI.unescape_html(next_page), verify_ssl: false).execute

        if response.code == 200
          # format response
          results = JSON.parse(response.to_str)

          # extract materials from results
          unless results['hits'].nil? and results['hits']['hits'].nil?
            hits = results['hits']['hits']
            hits.each do |item|
              process_material item
              processed += 1
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
      Scraper.log self.class.name + ': failed with: ' + e.message, 3
    end

    # log processed count
    Scraper.log self.class.name + ': materials extracted = ' + processed.to_s, 3

    return processed
  end

  def process_material(input)
    # map top-level tags
    metadata = input['metadata']
    links = input['links']

    # copy values
    begin
      material = Material.new
      material.contact = 'authors'
      material.status = 'active'
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
      add_material(material)
    rescue Exception => e
      Scraper.log self.class.name + 'Extract material fields failed with: ' + e.message, 4
    end
  end

end