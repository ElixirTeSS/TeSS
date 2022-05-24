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
    unless @events.nil? or @events.empty?
      # process each event
      @events.each do |event|
        @processed += 1

        # check for matched events
        begin
          matched_events = Event.where(title: event.title,
                                       url: event.url,
                                       start: event.start,
                                       content_provider: provider)

          if matched_events.nil? or matched_events.first.nil?
            # set ingestion parameters and save new event
            event.user = user
            event.content_provider = provider
            event.scraper_record = true
            event.last_scraped = DateTime.now
            event = set_field_defaults event
            save_valid_event event, false
          else
            # update and save matched event
            matched = overwrite_fields matched_events.first, event
            matched = set_field_defaults matched
            matched.scraper_record = true
            matched.last_scraped = DateTime.now
            save_valid_event matched, true
          end
        rescue Exception => e
          @messages << "#{self.class.name}: write events failed with: #{e.message}"
        end
      end
    end

    # finished
    @messages << "events processed[#{@processed}] added[#{@added}] updated[#{@updated}] rejected[#{@rejected}]"
    return
  end

  private

  def save_valid_event(resource, matched)
    if resource.valid?
      resource.save!
      matched ? @updated += 1 : @added += 1
    elsif resource.expired?
      @rejected += 1
      @messages << "Event has expired: #{resource.title}"
    else
      @rejected += 1
      @messages << "Event failed validation: #{resource.title}"
      resource.errors.full_messages.each do |m|
        @messages << "Error: #{m}"
      end
    end
  end

  def overwrite_fields (old_event, new_event)
    # overwrite unlocked attributes
    # [title, url, start, provider] not changed, as they are used for matching
    old_event.description = new_event.description unless old_event.field_locked? :description
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
    old_event.postcode = new_event.postcode unless old_event.field_locked? :postcode
    old_event.country = new_event.country unless old_event.field_locked? :country
    old_event.venue = new_event.venue unless old_event.field_locked? :venue
    return old_event
  end

  def set_field_defaults (event)
    # contact
    if event.contact.nil? or event.contact.blank?
      event.contact = event.content_provider.contact unless event.field_locked? :contact
    end

    # organizer
    if event.organizer.nil? or event.organizer.blank?
      event.organizer = event.content_provider.title unless event.field_locked? :organizer
    end

    # host institutions
    if event.host_institutions.nil? or event.host_institutions.size < 1
      event.host_institutions = [event.content_provider.title.to_s] unless event.field_locked? :host_institutions
    end

    # eligibility
    if event.eligibility.nil? or event.eligibility.size < 1
      event.eligibility = ['open_to_all'] unless event.field_locked? :eligibility
    end

    # return
    return event
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
    case input.downcase
    when 'conference'
      'conference'
    when 'class'
      'workshop'
    when 'networking'
      'meeting'
    when 'meetings_and_conferences'
      'meeting'
    when 'workshops_and_courses'
      'workshop'
    else
      nil
    end
  end

  def convert_location(input)
    #puts "convert_location(#{input})"
    result = nil

    # search for locations
    locations = Geocoder.search(input)
    if !locations.nil? and locations.size > 0
      if !locations.first.nil? and !locations.first.address.nil?
        #puts "address: #{locations.first.address.inspect}"
        result = locations.first.address
      end
    end

    # check substring
    if result.nil? or result['country'].nil?
      stripped = strip_first_part input
      result = convert_location(stripped.lstrip) if !stripped.nil? and stripped.size > 0
    end

    return result
  end

  def strip_first_part(input)
    parts = input.split(',')
    parts.shift
    return parts.join(',') if parts.size > 0
    return ''
  end

end
