# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# set log file
set :output, "shared/log/cron.log"

# Generate a new sitemap...
every :day, at: '6am' do
  rake "sitemap:generate"
end

# Process subscriptions...
every :day, at: '4am' do
  rake "tess:process_subscriptions"
end
