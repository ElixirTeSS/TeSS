class StaticController < ApplicationController
  def welcome
  end
  def about
  end
  def home
    render :layout => "home"
  end
end
