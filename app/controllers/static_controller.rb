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

    @content_providers = set_content_providers
    @featured_trainer = set_featured_trainer
    @events = set_upcoming_events
    @materials = set_latest_materials
    @count_strings = set_count_strings
  end

  def showcase
    @container_class = 'showcase-container container-fluid'
  end

  def set_featured_trainer
    return nil unless TeSS::Config.site.dig('home_page', 'featured_trainer')

    srand(Date.today.beginning_of_day.to_i)
    Trainer.order(:id).sample(1)
  end

  def set_content_providers
    ContentProvider
      .from_verified_users
      .where.not(image_file_size: nil)
      .sample(24)
  end

  def set_latest_materials
    n_materials = TeSS::Config.site.dig('home_page', 'latest_materials')
    return [] unless n_materials

    Material.search_and_filter(
      nil,
      '',
      {},
      sort_by: 'new',
      per_page: 10 * n_materials
    )&.results&.group_by(&:content_provider_id)&.map { |_p_id, p_materials| p_materials&.first }&.first(n_materials)
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
    ).results.group_by(&:content_provider_id).map { |_p_id, p_events| p_events.first }.first(n_events)
  end

  def set_count_strings
    count_strings = {}
    return count_strings unless TeSS::Config.site.dig('home_page', 'counters')

    count_strings['events'] = Event.where.not(end: nil).where('events.end > ?', Time.zone.now).count
    count_strings['last_month_events'] = Event.where('events.created_at > ?', 1.month.ago).count
    count_strings['materials'] = Material.all.count
    count_strings['workflows'] = Workflow.all.count
    count_strings['content_providers'] = ContentProvider.all.count
    count_strings['trainers'] = Trainer.all.count
    count_strings
  end
end
