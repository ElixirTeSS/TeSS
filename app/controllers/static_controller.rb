# The controller for actions related to home page
class StaticController < ApplicationController
  skip_before_action :authenticate_user!, :authenticate_user_from_token!

  def privacy; end

  def home
    @hide_search_box = true
    @resources = []
    if TeSS::Config.solr_enabled
      enabled = []
      enabled.append(Event) if TeSS::Config.feature['events']
      enabled.append(Material) if TeSS::Config.feature['materials']
      enabled.append(Collection) if TeSS::Config.feature['collections']
      enabled.each do |resource|
        @resources += resource.search_and_filter(nil, '', { 'max_age' => '1 month' },
                                                 sort_by: 'new', per_page: 5).results
      end
    end

    @resources = @resources.sort_by(&:created_at).reverse
    @events = set_upcoming_events
  end

  def showcase
    @container_class = 'showcase-container container-fluid'
  end

  def set_upcoming_events
    n_events = TeSS::Config.site.dig('home_page', 'upcoming_events')
    return [] unless n_events

    Event.search_and_filter(
      nil,
      '',
      { 'start' => "#{Date.tomorrow.beginning_of_day}/" },
      sort_by: 'early',
      per_page: 5 * n_events
    ).results.group_by(&:provider_id).map { |_p_id, p_events| p_events.first }.first(n_events)
  end
end
