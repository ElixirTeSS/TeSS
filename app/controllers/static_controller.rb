class StaticController < ApplicationController

  def about
  end

  def home
    render :layout => "home"
  end
end
