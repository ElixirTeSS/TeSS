# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
# http://github.com/javan/whenever
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
#
require 'yaml'
begin
  schedules = YAML.load_file("#{path}/config/schedule.yml")
rescue Exception => e
  # ignore failure
ensure
  # set to empty hash if not exists
  schedules ||= {}
end

# Generate a new sitemap...
if schedules['sitemap'].nil?
  every :day, at: '1am' do
    rake 'sitemap:generate'
  end
else
  every :"#{schedules['sitemap']['every']}", at: (schedules['sitemap']['at']).to_s do
    rake 'sitemap:generate'
  end
end

# Process subscriptions...
if schedules['subscriptions'].nil?
  every :day, at: '2am' do
    rake 'tess:process_subscriptions'
  end
else
  every :"#{schedules['subscriptions']['every']}", at: (schedules['subscriptions']['at']).to_s do
    rake 'tess:process_subscriptions'
  end
end

# Process ingestions
if schedules['ingestions'].nil?
  every :day, at: '3am' do
    rake 'tess:automated_ingestion'
  end
else
  every :"#{schedules['ingestions']['every']}", at: (schedules['ingestions']['at']).to_s do
    rake 'tess:automated_ingestion'
  end
end

if schedules['autocomplete_suggestions'].nil?
  every :tuesday, at: '5am' do
    rake 'tess:rebuild_autocomplete_suggestions'
  end
else
  every :"#{schedules['autocomplete_suggestions']['every']}", at: (schedules['autocomplete_suggestions']['at']).to_s do
    rake 'tess:rebuild_autocomplete_suggestions'
  end
end
