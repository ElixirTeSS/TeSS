module Ingestors
  module EventIngestion
    def add_event(event)
      if event.is_a?(Hash)
        c = EventsController.new
        c.params = { event: event }
        c.send(:event_params)
        event = OpenStruct.new(c.send(:event_params))
      end
      @events << event unless event.nil?
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

    def parse_dates(input, timezone = nil)
      Time.use_zone(timezone) do
        # try to split on obvious interval markers
        parts = input.gsub(/\(.*\)/, '').split(/and |till |-|—|–|to |tot /) # the whitespace is important (to is in October)
        # em-dash, en-dash, hyphen
        # splitting on - yields too many parts to do a proper parsing, so we fall through
        if parts.length > 1
          start = endt = nil

          begin
            start = Time.zone.parse(parts.first)
          rescue ArgumentError
          end
          begin
            # pretend it is 'start' now to make time-only work
            # Timecop.freeze(start) do
            #   endt = Time.zone.parse(parts.second) if parts.second
            # end
            endt = Time.zone.parse(parts.second, now=start) if parts.second
          rescue ArgumentError
          end

          # if one of the two failed to parse, find a numeric component
          # and replace it from the original in the other part
          if endt && !start || parts.first.length < 7
            begin
              start = Time.zone.parse(parts.second.sub(/[0-9:]+/, parts.first)) # or are days 0-based?
            rescue ArgumentError
            end
          end
          if start && !endt
            begin
              endt = Time.zone.parse(parts.first.sub(/[0-9:]+/, parts.second), now=start)
            rescue ArgumentError
            end
          end
        else
          start = endt = Time.zone.parse(input)
        end

        # if no end date given, use the start date
        endt ||= start

        return [start&.to_datetime, endt&.to_datetime]
      end
    end
  end
end
