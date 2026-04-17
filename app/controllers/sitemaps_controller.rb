class SitemapsController < ApplicationController
  def index
    if TeSS::Config.feature['spaces'] && !current_space.default?
      render file: Rails.root.join("public/sitemaps/#{current_space.host}/sitemap.xml"), layout: false
    else
      render file: Rails.root.join('public/sitemaps/sitemap.xml'), layout: false
    end
  end
end
