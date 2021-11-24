require 'ingestors/ingestor_event'
require 'open-uri'
require 'csv'

class IngestorEventCsv < IngestorEvent

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
      event = Event.new
      event.title = row['Title']
      event.url = row['URL']
      event.description = row['Description'].gsub!('"', '')
      event.start = row['Start']
      event.end = row['End']
      event.timezone = row['Timezone']
      event.contact = row['Contact']
      event.organizer = row['Organizer']
      event.eligibility = row['Eligibility'].split(/[;\s]/).reject(&:empty?).compact
      event.host_institutions = row['Host Institutions'].split(/[;\s]/).reject(&:empty?).compact
      event.online = row['Online']
      event.city = row['City']
      event.country = row['Country']
      event.venue = row['Venue']

      add_event(event)
      processed += 1
    end
    Scraper.log self.class.name + ': events extracted = ' + processed.to_s, 3
    return processed
  end

end
