require 'ingestors/ingestor_event'
require 'open-uri'
require 'csv'

class IngestorEventCsv < IngestorEvent

  def initialize
    super
  end

  def read (url)
    # parse csv file to table
    begin
      # parse csv as table
      web_contents = open(url).read
      table = CSV.parse web_contents, headers: true

      # process each row
      table.each do |row|
        # copy values
        event = Event.new
        event.title = get_column row, 'Title'
        event.url = process_url row, 'URL'
        event.description = process_description row ,'Description'
        event.start = get_column row, 'Start'
        event.end = get_column row, 'End'
        event.timezone = get_column row, 'Timezone'
        event.contact = get_column row, 'Contact'
        event.organizer = get_column row, 'Organizer'
        event.eligibility = process_array row, 'Eligibility'
        event.host_institutions = process_array row, 'Host Institutions'
        event.online = get_column row, 'Online'

        # copy optional values
        event.city = get_column row, 'City'
        event.country = get_column row, 'Country'
        event.venue = process_description row, 'Venue'
        event.postcode = get_column row, 'Postcode'
        event.subtitle = get_column row, 'Subtitle'
        event.duration = get_column row, 'Duration'
        event.recognition = get_column row, 'Recognition'
        event.event_types = process_array row, 'Types'
        event.cost_basis = get_column row, 'Cost Basis'
        event.cost_currency = get_column row, 'Currency'
        event.cost_value = get_column row, 'Cost'
        event.capacity = get_column row, 'Capacity'
        event.fields = process_array row, 'Fields'
        event.keywords = process_array row, 'Keywords'
        event.target_audience = process_array row, 'Audiences'
        event.learning_objectives = process_description row, 'Objectives'
        event.prerequisites = process_description row, 'Prerequisites'
        event.tech_requirements = process_description row, 'Requirements'

        # add to array
        if event.title.nil?
          @messages << "row found with no title"
        else
          add_event event
          @ingested += 1
        end
      end
    rescue CSV::MalformedCSVError => mce
      @messages << "parse table failed with: #{mce.message}"
    rescue Exception => e
      @messages << "parse table failed with: #{e.message}"
    end

    # finished
    return
  end

  private

end
