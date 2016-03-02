class StaticController < ActionController::Base

  layout 'application'

  def about
  end

  def home
    render :layout => "home"
  end
end
