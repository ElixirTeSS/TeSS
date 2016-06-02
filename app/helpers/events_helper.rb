module EventsHelper

  def events_for(resource=nil)
    return [] if resource.nil?

    return resource.events if resource.respond_to?(:events)

    events = []
    if resource.instance_of? Node
      resource.content_providers.each do |cp|
        cp.events.each do |event|
          events << cp.events
        end
      end
    end

    return events
  end

end
