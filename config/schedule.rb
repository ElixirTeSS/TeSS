# Use this file to easily define all of your cron jobs.
# http://github.com/javan/whenever
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
#
require 'yaml'
begin
  schedules = YAML.load_file("#{path}/config/schedule.yml")
rescue Exception => exception
  # ignore failure
ensure
  # set to empty hash if not exists
  schedules ||= {}
end

# Generate a new sitemap...
every schedules.dig('sitemap', 'every')&.to_sym || :day,
      at: schedules.dig('sitemap', 'at') || '1am' do
  rake "sitemap:refresh"
end

# Process subscriptions...
if !schedules['subscriptions'].nil?
  every :"#{schedules['subscriptions']['every']}", at: "#{schedules['subscriptions']['at']}" do
    rake "tess:process_subscriptions"
  end
else
  every :day, at: '2am' do
    rake "tess:process_subscriptions"
  end
end

# Process ingestions
if !schedules['ingestions'].nil?
  every :"#{schedules['ingestions']['every']}", at: "#{schedules['ingestions']['at']}" do
    rake "tess:automated_ingestion"
  end
else
  every :day, at: '3am' do
    rake "tess:automated_ingestion"
  end
end

# Curation mail
if !schedules['curation_mail'].nil?
  every :"#{schedules['curation_mail']['every']}", at: "#{schedules['curation_mail']['at']}" do
    rake "tess:event_curation_mails"
  end
else
  every :monday, at: '9am' do
    rake "tess:event_curation_mails"
  end
end

if !schedules['autocomplete_suggestions'].nil?
  every :"#{schedules['autocomplete_suggestions']['every']}", at: "#{schedules['autocomplete_suggestions']['at']}" do
    rake "tess:rebuild_autocomplete_suggestions"
  end
else
  every :tuesday, at: '5am' do
    rake "tess:rebuild_autocomplete_suggestions"
  end
end

if !schedules['dead_link_check'].nil?
  every :"#{schedules['dead_link_check']['every']}", at: "#{schedules['dead_link_check']['at']}" do
    rake "tess:check_resource_urls"
  end
else
  every :day, at: '6am' do
    rake "tess:check_resource_urls"
  end
end
