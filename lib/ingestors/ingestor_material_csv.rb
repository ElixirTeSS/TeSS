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
      material.description = row['Description'].gsub!('"', '')
      material.keywords = row['Keywords'].split(/[;\s]/).reject(&:empty?).compact
      material.contact = row['Contact']
      material.licence = row['Licence']
      material.status = row['Status']
      material.authors = row['Authors'].split(/[;\s]/).reject(&:empty?).compact if row['Authors']
      material.contributors = row['Contributors'].split(/[;\s]/).reject(&:empty?).compact if row['Contributors']

      add_material(material)
      processed += 1
    end
    Scraper.log self.class.name + ': materials extracted = ' + processed.to_s, 3
    return processed
  end

end