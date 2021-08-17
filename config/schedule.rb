# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# check input parameters
set(:db_user, 'tess_user') if !defined?(db_user)
set :db_name, "tess_#{environment}"

# set log file
set :output, "#{path}/shared/log/cron.log"

# Generate a new sitemap...
every :day, at: '6am' do
  rake "sitemap:generate"
end

# Process subscriptions...
every :day, at: '4am' do
  rake "tess:process_subscriptions"
end

every :sunday, at: '11pm' do
  script = "#{path}/scripts/pgsql_backup.sh"
  folder = "#{path}/shared/backups"
  command "#{script} #{db_user} #{db_name} #{folder} --exclude-schema=audit"
end

