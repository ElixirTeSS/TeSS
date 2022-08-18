# The helper for Events classes
module EventsHelper

  EVENTS_INFO = "An event in #{TeSS::Config.site['title_short']} is a link to a single training event sourced by a\
  provider along with description and other meta information (e.g. date, location, audience, ontological\
  categorization, keywords, etc.).\n\n\
  Training events can be added manually or automatically harvested from a provider's website.\n\n\
  If your website contains training events that you wish to include in #{TeSS::Config.site['title_short']},\
  please contact the support team (<a href='mailto:#{TeSS::Config.contact_email}'>#{TeSS::Config.contact_email}</a>)\
  for further details.".freeze

  def google_calendar_export_url(event)

    if event.all_day?
      # Need to add 1 day for all day events apparently
      dates = "#{event.start.strftime('%Y%m%d')}/#{event.end.tomorrow.strftime('%Y%m%d')}"
    else
      dates = "#{event.start_utc.strftime('%Y%m%dT%H%M00Z')}/#{event.end_utc.strftime('%Y%m%dT%H%M00Z')}"
    end

    if event.online?
      location = 'Online'
    else
      location = [event.venue, event.city, event.country].join(', ')
    end

    event_params = {
        text: event.title,
        dates: dates,
        ctz: event.timezone,
        details: "#{event_url(event)}",
        location: location,
        sf: true,
        output: 'xml'
    }

    "https://www.google.com/calendar/render?action=TEMPLATE&#{event_params.to_param}"
  end

  def ical_from_collection(events)
    cal = Icalendar::Calendar.new

    events.each do |event|
      cal.add_event(event.to_ical_event)
    end

    cal.to_ical
  end

  def csv_column_names
    return %w(Title Organizer Start End ContentProvider)
  end

  def csv_from_collection(events)
    CSV.generate do |csv|
      csv << csv_column_names
      events.each do |event|
        unless event.start.nil? or event.end.nil? or event.title.nil?
          csv << event.to_csv_event
        end
      end
    end
  end

  def google_maps_embed_api_tag(event)
    src = 'https://www.google.com/maps/embed/v1/place' +
      "?key=#{Rails.application.secrets.google_maps_api_key}" +
      "&q=#{event.latitude},#{event.longitude}"

    content_tag(:iframe, '', width: 400, height: 250, frameborder: 0, style: 'border: 0', class: 'google-map',
                    src: src, allowfullscreen: true)
  end

  def google_maps_javascript_api_tag(event)
    content_tag(:div, 'Loading map...', id: 'map', class: 'google-map', data: {
      'map-latitude': event.latitude,
      'map-longitude': event.longitude,
      'map-suggested-latitude': event.suggested_latitude,
      'map-suggested-longitude': event.suggested_longitude,
      'map-marker-title': event.title,
      'map-suggested-marker-image': image_url('suggestion.png')
    })
  end
end
