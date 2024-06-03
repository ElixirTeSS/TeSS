require 'yaml'

namespace :tess do
  desc 'create ContentProviders objects for all scrapers'
  task seed_content_providers: :environment do
    if TeSS::Config.ingestion.nil?
      config_file = File.join(Rails.root, 'config', 'ingestion.yml')
      TeSS::Config.ingestion = YAML.safe_load(File.read(config_file)).deep_symbolize_keys!
    end
    config = TeSS::Config.ingestion

    admin_user = User.all.select{|user| user.is_admin?}.first

    config[:sources].each do |source|
      if ContentProvider.find_by(title: source[:provider]).nil?
        ContentProvider.create!(
          title: source[:provider],
          url: source[:url],
          image_url: source[:image_url],
          user_id: admin_user.id,
        )
      end
    end
  end
end