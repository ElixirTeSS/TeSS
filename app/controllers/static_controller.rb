class StaticController < ActionController::Base

  layout 'home'

  def about
    @display_search_box = true
  end

  def home
    @display_search_box = false
  end
end
