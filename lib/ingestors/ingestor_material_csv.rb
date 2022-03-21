require 'ingestors/ingestor_material'
require 'open-uri'
require 'csv'

class IngestorMaterialCsv < IngestorMaterial

  def initialize
    super
  end

  def read (url)
    processed = 0
    messages = []

    begin
      # parse table
      web_contents = open(url).read
      table = CSV.parse(web_contents, headers: true)

      # process each row
      table.each do |row|
        # copy values
        material = Material.new
        material.title = row['Title']
        material.url = row['URL']
        material.description = process_description(row['Description'])
        material.keywords = row['Keywords'].split(/[;\s]/).reject(&:empty?).compact
        material.contact = row['Contact']
        material.licence = row['Licence']
        material.status = row['Status']
        material.authors = row['Authors'].split(/[;]/).reject(&:empty?).compact if row['Authors']
        material.contributors = row['Contributors'].split(/[;]/).reject(&:empty?).compact if row['Contributors']
        material.doi = row['DOI']

        # add to array
        add_material material
        processed += 1
      end
    rescue CSV::MalformedCSVError => mce
      messages << "parse table failed with: #{mce.message}"
    end

    # finished
    return processed, messages
  end

  private

  def process_description (input)
    convert_description(input.gsub!('"', '')) unless input.nil?
  end

end