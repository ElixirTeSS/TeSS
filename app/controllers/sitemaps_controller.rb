class SitemapsController < ApplicationController
  skip_before_action :authenticate_user!, :authenticate_user_from_token!

  def index
    if TeSS::Config.feature['spaces'] && !current_space.default?
      sitemap_path = sitemap_base.join("#{current_space.host}/sitemap.xml")
    else
      sitemap_path = sitemap_base.join('sitemap.xml')
    end

    return head :not_found unless sitemap_path.exist?

    render file: sitemap_path, layout: false, content_type: 'application/xml'
  end

  private

  def sitemap_base
    Rails.env.test? ? Rails.root.join('test/fixtures/files/sitemaps/') : Rails.root.join('public/sitemaps/')
  end
end
