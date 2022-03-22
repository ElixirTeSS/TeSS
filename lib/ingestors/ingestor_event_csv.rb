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
        event.title = row['Title']
        event.url = row['URL']
        event.description = process_description row['Description']
        event.start = row['Start']
        event.end = row['End']
        event.timezone = row['Timezone']
        event.contact = row['Contact']
        event.organizer = row['Organizer']
        event.eligibility = process_eligibility row['Eligibility']
        event.host_institutions = process_host_institutions row['Host Institutions']
        event.online = row['Online']
        event.city = row['City']
        event.country = row['Country']
        event.venue = row['Venue']

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

  def process_description (input)
    convert_description(input.gsub!('"', '')) unless input.nil?
  end

  def process_eligibility (input)
    input.split(/[;\s]/).reject(&:empty?).compact unless input.nil?
  end

  def process_host_institutions (input)
    input.split(/[;\s]/).reject(&:empty?).compact unless input.nil?
  end

end
