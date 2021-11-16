require 'open-uri'
require 'csv'

class IngestorCsvEvent < Ingestor

  def initialize
    super
  end

  def read (url)
    #puts "#{self.class.name} : read(#{url})"
    web_contents = open(url).read
    #puts "web_contents.class.name = " + web_contents.class.name
    table = CSV.parse(web_contents, headers: true)
    #puts "table.class.name = " + table.class.name
    processed = 0
    valid = 0
    table.each do |row|
      # copy values
      event = Event.new
      event.title = row['Title']
      event.url = row['URL']
      event.description = row['Description']
      event.start = row['Start']
      event.end = row['End']
      event.timezone = row['Timezone']
      event.contact = row['Contact']
      event.organizer = row['Organizer']
      event.eligibility = row['Eligibility'].split(/[,"]/).reject(&:empty?).compact
      event.host_institutions = row['Host Institutions'].split(/[,"]/).reject(&:empty?).compact
      event.online = row['Online']
      event.city = row['City']
      event.country = row['Country']
      event.venue = row['Venue']

      puts 'event: ' + event.inspect
      add_event(event)
    end
    puts 'events extracted = ' + processed.to_s
    puts 'rows valid = ' + valid.to_s
  end

  def write (user, provider)
    processed = 0
    ingested = 0
    @events.each do |event|
      processed += 1
      if valid_event?(event)
        # write event
        event.user = user
        event.content_provider = provider
        event.scraper_record = true
        event.last_scraped = DateTime.now
        event.save!
        ingested += 1
      end
    end
    log "Events ingested[#{ingested}] and rejected[#{processed - ingested}]"
  end

  def valid_event? (event)
    result = false
    # TODO: validate event

    return result
  end

end
