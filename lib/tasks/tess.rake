namespace :tess do

  desc "Populates the database with Node information from a JSON document"
  task load_node_json: :environment do
    path = File.join(Rails.root, 'config', 'data', 'elixir_nodes.json')

    raise "Couldn't find Node data at #{path}" unless File.exist?(path)

    hash = JSON.parse(File.read(path))
    nodes = Node.load_from_hash(hash, verbose: true)

    puts "#{nodes.select(&:valid?).count}/#{nodes.count} succeeded"
    puts "Done"
  end

  task download_images: :environment do
    ActiveRecord::Base.record_timestamps = false
    begin
      [Package, ContentProvider, StaffMember].each do |klass|
        downloadable = klass.all.select { |o| !o.image_url.blank? && !o.image? }
        if downloadable.length > 0
          puts "Downloading #{downloadable.length} images for #{klass.name}s"

          downloadable.each do |resource|
            begin
              resource.save!
            rescue Exception => e
              puts "Exception occurred fetching image for #{klass.name} ID: #{resource.id}"
              raise e
            end
          end
          puts
        else
          puts "No images to download for #{klass.name}s"
        end
      end
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
    puts "Done"
  end

  task expire_sessions: :environment do
    max_age = Devise.remember_for
    puts "Deleting sessions older than #{max_age.inspect}"
    deleted = ActiveRecord::SessionStore::Session.delete_all(['updated_at < ?', max_age.ago])
    puts "Deleted #{deleted} sessions"
  end

  task process_subscriptions: :environment do
    subs = Subscription.due
    puts "Processing #{subs.count} subscriptions:"
    subs.each do |sub|
      sub.process
      print '.'
    end
    puts
    puts "Done"
  end

end
