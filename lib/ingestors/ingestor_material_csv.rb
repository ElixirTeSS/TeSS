require 'ingestors/ingestor_material'
require 'open-uri'
require 'csv'

class IngestorMaterialCsv < IngestorMaterial

  def initialize
    super
  end

  def read (url)
    begin
      # parse table
      web_contents = open(url).read
      table = CSV.parse(web_contents, headers: true)

      # process each row
      table.each do |row|
        # copy values
        material = Material.new
        material.title = row['Title']
        material.url = row['URL'].strip unless row['URL'].nil?
        material.description = process_description row['Description']
        material.keywords = process_array row['Keywords']
        material.contact = row['Contact']
        material.licence = row['Licence']
        material.status = row['Status']
        material.authors = process_array row['Authors']
        material.contributors = process_array row['Contributors']
        material.doi = row['DOI']

        # add to
        add_material material
        @ingested += 1
      end
    rescue CSV::MalformedCSVError => mce
      @messages << "parse table failed with: #{mce.message}"
    end

    # finished
    return processed
  end

  private

  def process_description (input)
    convert_description(input.gsub('"', '')) unless input.nil?
  end

  def process_array (input)
    input.split(/[;\s]/).reject(&:empty?).compact unless input.nil?
  end

end
