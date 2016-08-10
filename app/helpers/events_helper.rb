module EventsHelper

  EVENTS_INFO = "An event in TeSS is a link to a single training event sourced by a provider along with description and other meta information (e.g. date, location, audience, ontological categorization, keywords, etc.).\n\n"+

      "TeSS harvests training events automatically, including descriptions and other relevant meta-data made available by providers.\n\n"+

      "If your website contains training events that you wish to include in TeSS, please contact the TeSS team (<a href='mailto:tess@elixir-uk.info'>tess@elixir-uk.info</a>) for further details."

  def events_for(resource=nil)
    return [] if resource.nil?

    return resource.events.flatten if resource.respond_to?(:events)

    events = []
    if resource.instance_of? Node
      resource.content_providers.each do |cp|
        cp.events.each do |event|
          events << event
        end
      end
    end
    return events
  end

  ICONS = {
      started: {:icon => 'fa-hourglass-half', :message => 'This event has already started'},
      expired: {:icon => 'fa-hourglass-end', :message => 'This event has finished'},
      online: {:icon => 'fa-desktop', :message => 'Accessible online'},
      for_profit: {:icon => 'fa-credit-card', :message => 'From a for-profit company'}
  }

  def icon_for(type, size=nil)

    return "<i class=\"fa #{ICONS[type][:icon]} has-tooltip event-info-icon#{'-' + size.to_s if size}\"
    aria-hidden=\"true\"
    data-toggle=\"tooltip\"
    data-placement=\"top\"
    title=\"#{ICONS[type][:message]}\">
    </i>".html_safe
  end

  def started_event

  end

  def expired_event

  end


end
