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

      # check for matched events
      matched_events = Event.where(title: event.title, url: event.url, content_provider: provider)

      if matched_events.nil? or matched_events.first.nil?
        # set ingestion parameters and save new event
        event.user = user
        event.content_provider = provider
        event.scraper_record = true
        event.last_scraped = DateTime.now
        if valid_event? event
          event.save!
          added += 1
        end

      else
        # update and save matched event
        matched = overwrite_fields matched_events.first, event
        matched.scraper_record = true
        matched.last_scraped = DateTime.now
        if valid_event? matched
          matched.save!
          updated += 1
        end

      end

    end
    written = (added + updated)
    Scraper.log self.class.name +
                  ": events added[#{added}] updated[#{updated}] rejected[#{processed - written}]", 3
    return written
  end

  def overwrite_fields (old_event, new_event)
    # overwrite unlocked attributes
    # [title, url, provider] not changed, as they are used for matching
    old_event.description = new_event.description unless old_event.field_locked? :description
    old_event.start = new_event.start unless old_event.field_locked? :start
    old_event.end = new_event.end unless old_event.field_locked? :end
    old_event.timezone = new_event.timezone unless old_event.field_locked? :timezone
    old_event.contact = new_event.contact unless old_event.field_locked? :contact
    old_event.organizer = new_event.organizer unless old_event.field_locked? :organizer
    old_event.eligibility = new_event.eligibility unless old_event.field_locked? :eligibility
    old_event.host_institutions = new_event.host_institutions unless old_event.field_locked? :host_institutions
    old_event.event_types = new_event.event_types unless old_event.field_locked? :event_types
    old_event.keywords = new_event.keywords unless old_event.field_locked? :keywords
    old_event.online = new_event.online unless old_event.field_locked? :online
    old_event.city = new_event.city unless old_event.field_locked? :city
    old_event.country = new_event.country unless old_event.field_locked? :country
    old_event.venue = new_event.venue unless old_event.field_locked? :venue

    # default fields
    if old_event.contact.nil? or old_event.contact.blank?
      old_event.contact = old_event.content_provider.contact unless old_event.field_locked? :contact
    end

    # return
    return old_event
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

  def convert_eligibility(input)
    case input
    when 'first_come_first_served'
      'open_to_all'
    when 'registration_of_interest'
      'expression_of_interest'
    when 'by_invitation'
      'by_invitation'
    else
      nil
    end
  end

  def convert_event_types(input)
    case input
    when 'meetings_and_conferences'
      'meeting'
    when 'workshops_and_courses'
      'workshop'
    else
      nil
    end
  end

end

