require 'ingestors/ingestor_material'
require 'open-uri'
require 'csv'

class IngestorMaterialCsv < IngestorMaterial

  def initialize
    super
  end

  def read (url)
    web_contents = open(url).read
    table = CSV.parse(web_contents, headers: true)
    processed = 0

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

      add_material(material)
      processed += 1
    end
    Scraper.log self.class.name + ': materials extracted = ' + processed.to_s, 3
    return processed
  end

  private

  def process_description (input)
    convert_description(input.gsub!('"', '')) unless input.nil?
  end

end