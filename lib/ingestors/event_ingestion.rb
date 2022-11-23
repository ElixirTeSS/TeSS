module Ingestors
  module EventIngestion
    def add_event(event)
      @events << event unless event.nil?
    end

    def write_events(user, provider)
      unless @events.nil? or @events.empty?
        # process each event
        @events.each do |event|
          @stats[:events][:processed] += 1

          # check for matched events
          event.user ||= user
          event.content_provider ||= provider
          existing_event = Event.check_exists(event)

          update = false
          if existing_event && existing_event.content_provider == provider
            update = true
            event = overwrite_event_fields(existing_event, event)
          end

          event = set_resource_defaults(event)
          save_valid_event(event, update)
        end
      end

      # finished
      nil
    end

    private

    def save_valid_event(resource, matched)
      if resource.valid?
        resource.save!
        @stats[:events][matched ? :updated : :added] += 1
      else
        @stats[:events][:rejected] += 1
        @messages << "Event failed validation: #{resource.title}"
        resource.errors.full_messages.each do |m|
          @messages << "Error: #{m}"
        end
      end
    end

    def overwrite_event_fields(old_event, new_event)
      locked_fields = old_event.locked_fields

      (new_event.changed - ['content_provider_id', 'user_id']).each do |attr|
        old_event.send("#{attr}=", new_event.send(attr)) unless locked_fields.include?(attr.to_sym)
      end

      old_event
    end

    def convert_eligibility(input)
      EligibilityDictionary.instance.lookup_value(input, 'title')
    end

    def convert_event_types(input)
      EventTypeDictionary.instance.lookup_value(input, 'title')
    end

    def convert_location(input)
      input
    end
  end
end
