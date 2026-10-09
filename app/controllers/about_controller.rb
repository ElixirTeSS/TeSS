class AboutController < ApplicationController
  before_action :check_external_link, only: [:tess, :registering, :learning_paths, :developers, :us]
  skip_before_action :authenticate_user!, :authenticate_user_from_token!

  def tess
  end

  def registering
  end

  def learning_paths
  end

  def developers
  end

  def us
  end

  private

  def check_external_link
    if TeSS::Config.site['about_us_link'].present?
      base = TeSS::Config.site['about_us_link'].to_s.chomp('/')
      action_name_map = {
        'tess' => '/',
        'registering' => '/content/intro-content/',
        'learning_paths' => '/content/learning-paths/',
        'developers' => '/developers/code-data/',
        'us' => '/overview/about/'
      }
      redirect_to "#{base}#{action_name_map.fetch(action_name)}", allow_other_host: true
    end
  end
end
