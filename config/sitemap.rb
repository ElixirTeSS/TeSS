base_path = Rails.env.test? ? 'test_sitemaps/' : 'sitemaps/'

# Lambda containing the sitemap content generation, evaluated inside a SitemapGenerator create block.
# Uses instance_exec so DSL methods (group, add) and route helpers are available via the LinkSet context.
generate_sitemap_content = lambda do |space|
  types = {
    materials: { resources: space.materials.from_verified_users, changefreq: 'daily', priority: 0.7 },
    events: { resources: space.events.from_verified_users, changefreq: 'daily', priority: 0.7 },
    content_providers: { resources: ContentProvider, changefreq: 'weekly', priority: 0.4 },
    workflows: { resources: space.workflows.from_verified_users.visible_by(nil), changefreq: 'daily', priority: 0.6 },
    collections: { resources: space.collections.from_verified_users.visible_by(nil), changefreq: 'daily', priority: 0.6 },
    learning_paths: { resources: space.learning_paths.visible_by(nil), changefreq: 'daily', priority: 0.6 }
  }

  group(filename: :site) do
    add root_path, changefreq: 'daily', priority: 1.0
    add about_path, priority: 0.4
    types.each do |type, options|
      next unless space.feature_enabled?(type.to_s)
      add polymorphic_path(type), lastmod: options[:resources].maximum(:updated_at), **options.except(:resources)
    end
  end

  types.each do |type, options|
    next unless space.feature_enabled?(type.to_s)
    group(filename: type) do
      options[:resources].find_each do |resource|
        add polymorphic_path(resource), lastmod: resource.updated_at
      end
    end
  end
end

# Always generate the global sitemap (for the default/main domain)
SitemapGenerator::Sitemap.default_host = TeSS::Config.base_url
SitemapGenerator::Sitemap.create(compress: false, sitemaps_path: base_path, include_root: false) do
  instance_exec(Space.default, &generate_sitemap_content)
end

# When spaces feature is enabled, also generate a separate sitemap for each space
if TeSS::Config.feature['spaces']
  begin
    Space.find_each do |space|
      Space.current_space = space
      SitemapGenerator::Sitemap.default_host = space.url
      SitemapGenerator::Sitemap.create(compress: false, sitemaps_path: "#{base_path}#{space.host}/", include_root: false) do
        instance_exec(space, &generate_sitemap_content)
      end
    end
  ensure
    Space.current_space = nil
    SitemapGenerator::Sitemap.default_host = TeSS::Config.base_url
  end
end
