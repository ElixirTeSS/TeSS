module EventsHelper

  EVENTS_INFO = "An event in TeSS is a link to a single training event sourced by a provider along with description and other meta information (e.g. date, location, audience, ontological categorization, keywords, etc.).\n\n"+

      "TeSS harvests training events automatically, including descriptions and other relevant meta-data made available by providers.\n\n"+

      "If your website contains training events that you wish to include in TeSS, please contact the TeSS team (<a href='mailto:tess@elixir-uk.info'>tess@elixir-uk.info</a>) for further details."

  def google_calendar_export_url(event)
    if event.all_day?
      dates = "#{event.start.strftime('%Y%m%d')}/#{event.end.tomorrow.strftime('%Y%m%d')}" # Need to add 1 day for all day events apparently
    else
      dates = "#{event.start.strftime('%Y%m%dT%H%M00Z')}/#{event.end.strftime('%Y%m%dT%H%M00Z')}"
    end

    event_params = {
        text: event.title,
        dates: dates,
        details: "#{event_url(event)}",
        location: [event.venue, event.city, event.country].join(', '),
        sf: true,
        output: 'xml'
    }

    "https://www.google.com/calendar/render?action=TEMPLATE&#{event_params.to_param}"
  end
end
