module Ingestors
  module EventIngestion
    def add_event(event)
      event = OpenStruct.new(event) if event.is_a?(Hash)
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
  end
end
