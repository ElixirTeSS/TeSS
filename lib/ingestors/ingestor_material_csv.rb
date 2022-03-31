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
        material.title = get_column row, 'Title'
        material.url = process_url row, 'URL'
        material.description = process_description row, 'Description'
        material.keywords = process_array row, 'Keywords'
        material.contact = get_column row, 'Contact'
        material.licence = get_column row, 'Licence'
        material.status = get_column row, 'Status'

        # copy optional values
        material.doi = get_column row, 'DOI'
        material.version = get_column row, 'Version'
        material.date_published = get_column row, 'Published'
        material.date_modified = get_column row, 'Modified'
        material.difficulty_level = process_competency row, 'Competency'
        material.authors = process_array row, 'Authors'
        material.contributors = process_array row, 'Contributors'
        material.fields = process_array row, 'Fields'
        material.target_audience = process_array row, 'Audiences'
        material.resource_type = process_array row, 'Types'
        material.other_types = get_column row, 'Other Types'
        material.learning_objectives = process_description row, 'Objectives'
        material.prerequisites = process_description row, 'Prerequisites'
        material.syllabus = process_description row, 'Syllabus'

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

  def process_competency(row,header)
    row[header].nil? ? 'notspecified' : row[header]
  end

end
