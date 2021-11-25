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

        puts "url = " + next_page.to_s
        response = RestClient::Request.new(method: :get, url: url, verify_ssl: false).execute

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

=begin
    web_contents = open(url).read
    table = CSV.parse(web_contents, headers: true)

    # process each row
    table.each do |row|
      # copy values
      material = Material.new
      material.title = row['Title']
      material.url = row['URL']
      material.description = row['Description'].gsub!('"', '')
      material.keywords = row['Keywords'].split(/[;\s]/).reject(&:empty?).compact
      material.contact = row['Contact']
      material.licence = row['Licence']
      material.status = row['Status']
      add_material(material)
      processed += 1
    end
=end
  end

end