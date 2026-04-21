class SitemapsController < ApplicationController
  skip_before_action :authenticate_user!, :authenticate_user_from_token!

  def index
    if TeSS::Config.feature['spaces'] && !current_space.default?
      render file: sitemap_base.join("#{current_space.host}/sitemap.xml"), layout: false
    else
      render file: sitemap_base.join('sitemap.xml'), layout: false
    end
  end

  private

  def sitemap_base
    Rails.env.test? ? Rails.root.join('test/fixtures/files/sitemaps/') : Rails.root.join('public/sitemaps/')
  end
end
