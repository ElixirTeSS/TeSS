class StaticController < ApplicationController

  skip_before_action :authenticate_user!, :authenticate_user_from_token!

  def about
  end

  def home
    @hide_search_box = true
  end

end
