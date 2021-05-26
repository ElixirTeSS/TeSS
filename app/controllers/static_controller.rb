# The controller for actions related to home page
class StaticController < ApplicationController

  skip_before_action :authenticate_user!, :authenticate_user_from_token!

  def privacy; end

  def home
    @hide_search_box = true
    @resources = []
    if TeSS::Config.solr_enabled
      [Event, Material].each do |resource|
        @resources += resource.search_and_filter(nil, '', { 'max_age' => '1 month' }, sort_by: 'new', per_page: 5).results
      end
    end

    # count the home features switched on and set the width
    home_keys = %w[events materials providers workflows]
    home_features = TeSS::Config.feature.select {|k,v| home_keys.include? k}
    on_features = home_features.select {|k,v| v == true}

    case on_features.size
    when 2
      @liclass = "pair"
    when 3
      @liclass = "triple"
    else
      @liclass = "quad"
    end

    @resources = @resources.sort_by(&:created_at).reverse
  end
end
