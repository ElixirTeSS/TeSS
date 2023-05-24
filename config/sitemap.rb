# frozen_string_literal: true

# Change this to your host. See the readme at https://github.com/lassebunk/dynamic_sitemaps
# for examples of multiple hosts and folders.
base_url = URI.parse(TeSS::Config.base_url)
host_with_port = base_url.host
host_with_port += ":#{base_url.port}" if base_url.port != base_url.default_port

protocol base_url.scheme
host host_with_port

sitemap :site do
  url root_url, last_mod: Time.zone.now, change_freq: 'daily', priority: 1.0
  url about_url, change_freq: 'weekly', priority: 0.4
  url materials_url, last_mod: Time.zone.now, change_freq: 'daily', priority: 0.7 if TeSS::Config.feature['materials']
  url events_url, last_mod: Time.zone.now, change_freq: 'daily', priority: 0.7 if TeSS::Config.feature['events']
  url workflows_url, last_mod: Time.zone.now, change_freq: 'daily', priority: 0.6 if TeSS::Config.feature['workflows']
  if TeSS::Config.feature['content_providers']
    url content_providers_url, last_mod: Time.zone.now, change_freq: 'weekly', priority: 0.4
  end
end

# You can have multiple sitemaps like the above – just make sure their names are different.

# Automatically link to all pages using the routes specified
# using "resources :pages" in config/routes.rb. This will also
# automatically set <lastmod> to the date and time in page.updated_at:
#
#   sitemap_for Page.scoped

sitemap_for Material.from_verified_users if TeSS::Config.feature['materials']
sitemap_for Event.from_verified_users if TeSS::Config.feature['events']
sitemap_for ContentProvider if TeSS::Config.feature['content_providers']
sitemap_for Workflow.from_verified_users.visible_by(nil) if TeSS::Config.feature['workflows']

# For products with special sitemap name and priority, and link to comments:
#
#   sitemap_for Product.published, name: :published_products do |product|
#     url product, last_mod: product.updated_at, priority: (product.featured? ? 1.0 : 0.7)
#     url product_comments_url(product)
#   end

# If you want to generate multiple sitemaps in different folders (for example if you have
# more than one domain, you can specify a folder before the sitemap definitions:
#
#   Site.all.each do |site|
#     folder "sitemaps/#{site.domain}"
#     host site.domain
#
#     sitemap :site do
#       url root_url
#     end
#
#     sitemap_for site.products.scoped
#   end

# Ping search engines after sitemap generation:
#

ping_with "#{base_url.scheme}://#{host}/sitemap.xml" if Rails.env.production?
