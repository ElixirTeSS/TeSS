# The controller for actions related to the about pages
class AboutController < ApplicationController

  skip_before_action :authenticate_user!, :authenticate_user_from_token!
  
  def tess
  end

  def us
  end

  def registering
  end

  def developers
  end

end
