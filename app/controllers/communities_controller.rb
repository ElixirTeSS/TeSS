# The controller for actions related to home page
class CommunitiesController < ApplicationController
  before_action :set_community
  skip_before_action :authenticate_user!, :authenticate_user_from_token!

  def show
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

    @featured_trainer = nil # set_featured_trainer
    @events = set_upcoming_events
    @materials = set_latest_materials
  end

  private

  def set_featured_trainer
    srand(Date.today.beginning_of_day.to_i)
    Trainer.order(:id).sample(1)
  end

  def set_latest_materials
    n_materials = 5

    Material.search_and_filter(
      nil,
      '',
      { **@community.filters },
      sort_by: 'new',
      per_page: 10 * n_materials
    )&.results&.group_by(&:content_provider_id)&.map { |_p_id, p_materials| p_materials&.first }&.first(n_materials)
  end

  def set_upcoming_events
    n_events = 5

    Event.search_and_filter(
      nil,
      '',
      {
        'include_expired' => 'true',
        'start' => "#{10.years.ago.beginning_of_day}/",
        **@community.filters
      },
      sort_by: 'early',
      per_page: 5 * n_events
    ).results.group_by(&:content_provider_id).map { |_p_id, p_events| p_events.first }.first(n_events)
  end

  def set_community
    @community = Community.find(params[:id])
    raise ActionController::RoutingError.new('Not a recognized community') unless @community
  end
end
