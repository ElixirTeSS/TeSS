require 'yaml'

namespace :tess do

  task :remove_spam_activities, [:type] => [:environment] do |t, args|
    types = args[:type] ? [args[:type].constantize] : [Node, Workflow, ContentProvider, Material, Event]
    total_deleted_count = 0
    total_activity_count = PublicActivity::Activity.count
    puts "#{total_activity_count} activities in database"

    types.each do |type|
      deleted_count = 0
      records = (type == Event) ? type.all.select(&:upcoming?) : type.all
      puts "Looking at #{records.count} #{type.name.pluralize}:"
      records.each do |record|
        ##########
        # Delete `update_parameter` activities for ignored attributes
        ignored = record.activities.where(key: "#{type.name.underscore}.update_parameter").select do |activity|
          LogParameterChanges::IGNORED_ATTRIBUTES.include?(activity.parameters[:attr])
        end
        if ignored.any?
          deleted_count += ignored.count
          ignored.each(&:destroy)
        end

        ##########
        # Delete `update_parameter` activities that just shuffle array elements around
        array_changes = record.activities.where(key: "#{type.name.underscore}.update_parameter").select do |activity|
          activity.parameters[:new_val].is_a?(Array)
        end
        grouped = array_changes.group_by { |a| a.parameters[:attr] }
        # Compare each parameter change activity with the one preceding it (for the same attribute) and check if they
        # are the same value (when sorted). If so, delete the newer one.
        grouped.each_value do |activities|
          activities.to_a.unshift(nil).reverse.each_cons(2) do |newer, older|
            if newer && older
              if newer.parameters[:new_val].length == older.parameters[:new_val].length &&
                newer.parameters[:new_val].sort == older.parameters[:new_val].sort
                newer.destroy
                deleted_count += 1
              end
            end
          end
        end

        ##########
        # Delete now-redundant `update` activities without any associated parameter changes
        updates = record.activities.where(key: "#{type.name.underscore}.update")
        updates.each do |activity|
          # Have to do this very awkward query due to `update_parameter` activities being created separately from
          # `update` activities and not necessarily at the same time!
          if record.activities.where(key: "#{type.name.underscore}.update_parameter").
            where('id < ?', activity.id).
            where('created_at > ?', (activity.created_at - 2.seconds)).none?
            activity.destroy
            deleted_count += 1
          end
        end
        print '.'
      end
      puts
      puts "Deleted #{deleted_count} #{type} activities"
      total_deleted_count += deleted_count
    end

    puts
    puts "Deleted #{total_deleted_count} activities in total"
    puts "Done"
  end

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
    puts "Deleting sessions older than #{max_age.inspect} at #{Time.now}:"
    deleted = ActiveRecord::SessionStore::Session.delete_all(['updated_at < ?', max_age.ago])
    puts "Deleted #{deleted} sessions"
  end

  task process_subscriptions: :environment do
    subs = Subscription.due
    puts "Processing #{subs.count} subscriptions at #{Time.now}: "
    subs.each do |sub|
      sub.process
      print '.'
    end
    puts " Done"
  end

  task reset_subscriptions: :environment do
    subs = Subscription.all
    puts "Resetting #{subs.count} subscriptions at #{Time.now}:"
    subs.each do |sub|
      sub.reset_due
      print '.'
    end
    puts " Done"
  end

  desc 'run generic ingestion process'
  task automated_ingestion: :environment do
    begin
      if TeSS::Config.ingestion.nil?
        config_file = File.join(Rails.root, 'config', 'ingestion.yml')
        TeSS::Config.ingestion = YAML.safe_load(File.read(config_file)).deep_symbolize_keys!
      end
      raise 'Config.ingestion is nil' if TeSS::Config.ingestion.nil?
      #  set log file
      log_path = File.join(Rails.root, TeSS::Config.ingestion[:logfile])
      log_file = File.open(log_path, 'w')
      log_file.puts 'Task: automated_ingestion'
      start = Time.now
      log_file.puts '   Started at... ' + start.strftime("%Y-%m-%d %H:%M:%s")

      begin
        Scraper.run(log_file)
      rescue Exception => e
        log_file.puts('   Run Scraper failed with: ' + e.message)
      end

      # wrap up
      finish = Time.now
      log_file.puts '   Finished at.. ' + finish.strftime("%Y-%m-%d %H:%M:%s")
      log_file.puts "   Time taken was #{(1000 * (finish.to_f - start.to_f)).round(3)} ms"
      log_file.puts 'Done.'
      log_file.close
    rescue Exception => e
      puts "task[automated_ingestion] failed with #{e.message}"
    end
  end

  desc 'check and update time zones'
  task check_timezones: :environment do
    puts "Task: check_timezones - start"
    overrides = { 'AEDT' => 'Sydney',
                  'AEST' => 'Sydney' }
    begin
      messages = []
      processed = 0
      unchanged = 0
      updated = 0
      failed = 0
      Event.all.each do |event|
        processed += 1
        pre_tz = event.timezone
        event.check_timezone
        event.timezone = overrides[event.timezone] if overrides.keys.include? event.timezone
        if event.save
          unless event.timezone == pre_tz
            updated += 1
            messages << "event[#{event.title}] updated to timezone[#{event.timezone}]"
          else
            unchanged += 1
          end
        else
          failed += 1
          messages << "event[#{event.slug}] update failed: timezone = #{event.timezone}"
          event.errors.full_messages.each { |m| messages << "   #{m}" }
        end
      end
    rescue Exception => e
      messages << "task tess:check_timezones failed with: #{e.message}"
    end
    messages.each { |m| puts m }
    puts "Task: check_timezones - processed[#{processed}] unchanged[#{unchanged}] updated[#{updated}] failed[#{failed}]"
    puts "Task: check_timezones - finished."
  end

end
