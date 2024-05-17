require 'yaml'

namespace :tess do
  task :remove_spam_activities, [:type] => [:environment] do |_t, args|
    types = args[:type] ? [args[:type].constantize] : [Node, Workflow, ContentProvider, Material, Event]
    total_deleted_count = 0
    total_activity_count = PublicActivity::Activity.count
    puts "#{total_activity_count} activities in database"

    types.each do |type|
      deleted_count = 0
      records = type == Event ? type.all.not_finished : type.all
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
            next unless newer && older && (newer.parameters[:new_val].length == older.parameters[:new_val].length &&
                 newer.parameters[:new_val].sort == older.parameters[:new_val].sort)

            newer.destroy
            deleted_count += 1
          end
        end

        ##########
        # Delete now-redundant `update` activities without any associated parameter changes
        updates = record.activities.where(key: "#{type.name.underscore}.update")
        updates.each do |activity|
          # Have to do this very awkward query due to `update_parameter` activities being created separately from
          # `update` activities and not necessarily at the same time!
          next unless record.activities.where(key: "#{type.name.underscore}.update_parameter")
                            .where('id < ?', activity.id)
                            .where('created_at > ?', (activity.created_at - 2.seconds)).none?

          activity.destroy
          deleted_count += 1
        end
        print '.'
      end
      puts
      puts "Deleted #{deleted_count} #{type} activities"
      total_deleted_count += deleted_count
    end

    puts
    puts "Deleted #{total_deleted_count} activities in total"
    puts 'Done'
  end

  desc 'Populates the database with Node information from a JSON document'
  task load_node_json: :environment do
    path = File.join(Rails.root, 'config', 'data', 'elixir_nodes.json')

    raise "Couldn't find Node data at #{path}" unless File.exist?(path)

    hash = JSON.parse(File.read(path))
    nodes = Node.load_from_hash(hash, verbose: true)

    puts "#{nodes.select(&:valid?).count}/#{nodes.count} succeeded"
    puts 'Done'
  end

  task download_images: :environment do
    ActiveRecord::Base.record_timestamps = false
    begin
      [Collection, ContentProvider, StaffMember].each do |klass|
        downloadable = klass.all.select { |o| !o.image_url.blank? && !o.image? }
        if downloadable.length > 0
          puts "Downloading #{downloadable.length} images for #{klass.name}s"

          downloadable.each do |resource|
            resource.save!
          rescue Exception => e
            puts "Exception occurred fetching image for #{klass.name} ID: #{resource.id}"
            raise e
          end
          puts
        else
          puts "No images to download for #{klass.name}s"
        end
      end
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
    puts 'Done'
  end

  task expire_sessions: :environment do
    max_age = Devise.remember_for
    puts "Deleting sessions older than #{max_age.inspect} at #{Time.now}:"
    deleted = ActiveRecord::SessionStore::Session.where('updated_at < ?', max_age.ago).delete_all
    puts "Deleted #{deleted} sessions"
  end

  task process_subscriptions: :environment do
    subs = Subscription.due
    puts "Processing #{subs.count} subscriptions at #{Time.now}: "
    subs.each do |sub|
      sub.process
      print '.'
    end
    puts ' Done'
  end

  task reset_subscriptions: :environment do
    subs = Subscription.all
    puts "Resetting #{subs.count} subscriptions at #{Time.now}:"
    subs.each do |sub|
      sub.reset_due
      print '.'
    end
    puts ' Done'
  end

  desc 'run generic ingestion process'
  task automated_ingestion: :environment do
    scraper = Scraper.new
    scraper.run
    log = scraper.log_file
    log.close
    puts "Finished successfully, output written to: #{log.path}"
  end

  desc 'mail content providers for curation of scraped events'
  task event_curation_mails: :environment do
    cut_off_time = Time.zone.now - 1.week
    providers = ContentProvider.all.filter { |provider| provider.send_event_curation_email }
    providers.each do |provider|
      CurationMailer.events_require_approval(provider, cut_off_time).deliver_later
    end
    puts 'Curation mails sent'
  end

  desc 'check and update time zones'
  task check_timezones: :environment do
    puts 'Task: check_timezones - start'
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
          if event.timezone == pre_tz
            unchanged += 1
          else
            updated += 1
            messages << "event[#{event.title}] updated to timezone[#{event.timezone}]"
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
    puts 'Task: check_timezones - finished.'
  end

  desc 'Fetch and convert SPDX licenses from GitHub'
  task fetch_spdx: :environment do
    old_licenses = YAML.load(File.read(File.join(Rails.root, 'config', 'dictionaries', 'licences_old.yml')))
    url = 'https://raw.githubusercontent.com/spdx/license-list-data/master/json/licenses.json'
    json = URI.open(url).read
    hash = JSON.parse(json)
    transformed = {
      'notspecified' => {
        'title' => 'License Not Specified'
      },
      'other-at' => {
        'title' => 'Other (Attribution)'
      },
      'other-closed' => {
        'title' => 'Other (Not Open)'
      },
      'other-nc' => {
        'title' => 'Other (Non-Commercial)'
      },
      'other-open' => {
        'title' => 'Other (Open)'
      },
      'other-pd' => {
        'title' => 'Other (Public Domain)'
      }
    }
    hash['licenses'].each do |license|
      id = license.delete('licenseId')
      license['title'] = license.delete('name')
      transformed[id] = license.transform_keys(&:underscore)
      # Supplement with URLs from old licences dictionary
      old_url = old_licenses.dig(id, 'url')
      transformed[id]['see_also'] << old_url unless old_url.blank? || transformed[id]['see_also'].include?(old_url)
    end

    File.write(File.join(Rails.root, 'config', 'dictionaries', 'licences.yml'), transformed.to_yaml)
  end

  desc 'Rebuild autocomplete suggestions'
  task rebuild_autocomplete_suggestions: :environment do
    suggestions = {}
    [Material, Event, Collection, Workflow, Profile].each do |type|
      type.suggestion_fields_to_add.each do |field|
        suggestions[field] ||= Set.new
        type.pluck(field).flatten.each { |s| suggestions[field].add(s) }
      end
    end

    suggestions.each do |field, values|
      next unless values.any?

      puts "Updating #{field} suggestions..."
      count = AutocompleteSuggestion.refresh(field, *values)
      puts "  Deleted #{count} redundant suggestions" if count > 0
    end

    with_redundant_fields = AutocompleteSuggestion.where.not(field: suggestions.keys)
    if with_redundant_fields.any?
      puts "Deleted #{with_redundant_fields.count} suggestions from unused fields"
      with_redundant_fields.destroy_all
    end

    puts 'Done'
  end
end
