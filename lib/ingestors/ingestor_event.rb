require 'ingestors/ingestor'

class IngestorEvent < Ingestor

  @events = Array.new

  def initialize
    super
    @events = []
  end

  def add_event (event)
    @events << event if !event.nil?
  end

  def write (user, provider)
    processed = 0
    updated = 0
    added = 0
    @events.each do |event|
      processed += 1

      # check exists
      matched_events = Event.where(title: event.title, url: event.url, content_provider: provider)

      if matched_events.nil? or matched_events.first.nil?
        # set ingestion parameters
        event.user = user
        event.content_provider = provider
        event.scraper_record = true
        event.last_scraped = DateTime.now

        # save new event
        if valid_event? event
          event.save!
          added += 1
        end

      else
        # overwrite unlocked attributes
        old_event = matched_events.first
        old_event.locked_fields.nil? ? locked = [] : locked = old_event.locked_fields

        old_event.url = event.url unless locked.include? :url
        old_event.description = event.description unless locked.include? :description
        old_event.start = event.start unless locked.include? :start
        old_event.end = event.end unless locked.include? :end
        old_event.timezone = event.timezone unless locked.include? :timezone
        old_event.contact = event.contact unless locked.include? :contact
        old_event.organizer = event.organizer unless locked.include? :organizer
        old_event.eligibility = event.eligibility unless locked.include? :eligibility
        old_event.host_institutions = event.host_institutions unless locked.include? :host_institutions
        old_event.online = event.online unless locked.include? :online
        old_event.city = event.city unless locked.include? :city
        old_event.country = event.country unless locked.include? :country
        old_event.venue = event.venue unless locked.include? :venue

        # save updated event
        # do not override user and provider
        old_event.scraper_record = true
        old_event.last_scraped = DateTime.now
        if valid_event? old_event
          old_event.save!
          updated += 1
        end

      end

    end
    Scraper.log self.class.name +
                  ": events added[#{added}] updated[#{updated}] rejected[#{processed - (added + updated)}]", 3
    return processed
  end

  def valid_event? (event)
    # check event attributes
    return true if event.valid?

    # log error messages
    Scraper.log "Event title[#{event.title}] failed validation.", 4
    event.errors.full_messages.each do |message|
      Scraper.log "Event title[#{event.title}] error: " + message, 5
    end

    return false
  end

end

