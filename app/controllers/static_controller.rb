class StaticController < ApplicationController

  skip_before_action :authenticate_user!, :authenticate_user_from_token!

  def about
  end

  def home
    @hide_search_box = true
    @materials = Material.between_times(Time.zone.now - 1.month, Time.zone.now).limit(5)
  end

end
