require 'open-uri'
require 'csv'
require 'cgi'

module Ingestors
  class MaterialCsvIngestor < Ingestor
    include CsvIngestion

    def self.config
      {
        key: 'material_csv',
        title: 'CSV File and Google Spreadsheet',
        category: :materials
      }
    end

    def read(url)
      begin
        # Google spreadsheet convertor
        url = gsheet_to_csv(url)

        # parse table
        web_contents = open_url(url).read
        table = CSV.parse(web_contents, headers: true)

        # process each row
        table.each do |row|
          # copy values
          material = OpenStruct.new
          material.title = get_column row, 'Title'
          material.url = process_url row, 'URL'
          material.description = process_description row, 'Description'
          material.keywords = process_array row, 'Keywords'
          material.contact = get_column row, 'Contact'
          material.licence = process_licence row, 'Licence'
          material.status = get_column row, 'Status'

          # copy optional values
          material.doi = get_column row, 'DOI'
          material.version = get_column row, 'Version'
          material.date_created = get_column row, 'Created'
          material.date_published = get_column row, 'Published'
          material.date_modified = get_column row, 'Modified'
          material.difficulty_level = process_competency row, 'Competency'
          material.person_links_attributes = process_authors(process_array(row, 'Authors'))
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
        end
      rescue CSV::MalformedCSVError => e
        @messages << "parse table failed with: #{e.message}"
      end

      # finished
      processed
    end

    private

    def process_authors(authors_array)
      return [] if authors_array.blank?
      
      authors_array.map do |author_name|
        # Parse name into first and last name
        name_parts = author_name.to_s.strip.split(/\s+/, 2)
        first_name = name_parts.length > 1 ? name_parts[0] : ''
        last_name = name_parts.length > 1 ? name_parts[1] : name_parts[0]
        
        {
          role: 'author',
          person_attributes: {
            first_name: first_name,
            last_name: last_name,
            orcid: nil
          }
        }
      end
    end

    def process_competency(row, header)
      row[header].nil? ? 'notspecified' : row[header]
    end

    def process_licence(row, header)
      row[header].nil? ? 'notspecified' : row[header]&.to_s&.lstrip
    end

    # if url is a raw google spreadsheet
    # it returns the Google spreadsheet CSV export
    # else it returns the url
    def gsheet_to_csv(url)
      return url unless url.include? 'docs.google.com/spreadsheets/d/'

      spreadsheet_id = url.partition('d/').last.partition('/').first
      gid = CGI.parse(URI.parse(url).query)['gid']&.first
      "https://docs.google.com/spreadsheets/d/#{spreadsheet_id}/export?gid=#{gid}&exportFormat=csv"
    end
  end
end
