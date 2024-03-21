# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = TeSS::Config.base_url

SitemapGenerator::Sitemap.create(compress: false, sitemaps_path: Rails.env.test? ? 'test_sitemaps/' : 'sitemaps/', include_root: false) do
  types = {
    materials: { resources: Material.from_verified_users, changefreq: 'daily', priority: 0.7 },
    events: { resources: Event.from_verified_users, changefreq: 'daily', priority: 0.7 },
    content_providers: { resources: ContentProvider, changefreq: 'weekly', priority: 0.4 },
    workflows: { resources: Workflow.from_verified_users.visible_by(nil), changefreq: 'daily', priority: 0.6 },
    collections: { resources: Collection.from_verified_users.visible_by(nil), changefreq: 'daily', priority: 0.6 },
    learning_paths: { resources: LearningPath.visible_by(nil), changefreq: 'daily', priority: 0.6 }
  }

  group(filename: :site) do
    add root_path, changefreq: 'daily', priority: 1.0
    add about_path, priority: 0.4
    types.each do |type, options|
      next unless TeSS::Config.feature[type.to_s]
      add polymorphic_path(type), lastmod: options[:resources].maximum(:updated_at), **options.except(:resources)
    end
  end

  types.each do |type, options|
    next unless TeSS::Config.feature[type.to_s]
    group(filename: type) do
      options[:resources].find_each do |resource|
        add polymorphic_path(resource), lastmod: resource.updated_at
      end
    end
  end
end
