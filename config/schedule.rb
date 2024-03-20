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
rescue Exception
  # ignore failure
ensure
  # set to empty hash if not exists
  schedules ||= {}
end

# Generate a new sitemap...
every schedules.dig('sitemap', 'every')&.to_sym || :day,
      at: schedules.dig('sitemap', 'at') || '1am' do
  rake 'sitemap:refresh'
end

# Process subscriptions...
if !schedules['subscriptions'].nil?
  every :"#{schedules['subscriptions']['every']}", at: (schedules['subscriptions']['at']).to_s do
    rake 'tess:process_subscriptions'
  end
else
  every :day, at: '2am' do
    rake 'tess:process_subscriptions'
  end
end

# Process ingestions
if !schedules['ingestions'].nil?
  every :"#{schedules['ingestions']['every']}", at: (schedules['ingestions']['at']).to_s do
    rake 'tess:automated_ingestion'
  end
else
  every :day, at: '3am' do
    rake 'tess:automated_ingestion'
  end
end

if !schedules['autocomplete_suggestions'].nil?
  every :"#{schedules['autocomplete_suggestions']['every']}", at: (schedules['autocomplete_suggestions']['at']).to_s do
    rake 'tess:rebuild_autocomplete_suggestions'
  end
else
  every :tuesday, at: '5am' do
    rake 'tess:rebuild_autocomplete_suggestions'
  end
end
