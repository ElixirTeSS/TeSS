class SitemapsController < ApplicationController
  def index
    if TeSS::Config.feature['spaces'] && !current_space.default?
      redirect_to "/sitemaps/#{current_space.host}/sitemap.xml"
    else
      redirect_to '/sitemaps/sitemap.xml'
    end
  end
end
