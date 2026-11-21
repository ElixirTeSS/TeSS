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
    links = TeSS::Config.site['external_about_links']
    return unless links&.fetch('enabled', false)

    target_url = links[action_name]
    redirect_to target_url, allow_other_host: true if target_url.present?
  end
end
