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

# check input parameters
set(:db_user, 'tess_user') if !defined?(db_user)
set :db_name, "tess_#{environment}"
set :bkup_script, "#{path}/scripts/pgsql_backup.sh"
set :bkup_folder, "#{path}/shared/backups"

# set log file
set :log_folder, "#{path}/shared/log"
set :output, "#{log_folder}/cron.log"

# Generate a new sitemap...
if !schedules['sitemap'].nil?
  every :"#{schedules['sitemap']['every']}", at: "#{schedules['sitemap']['at']}" do
    rake "sitemap:generate"
  end
else
  every :day, at: '1am' do
    rake "sitemap:generate"
  end
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

# run database backups
if !schedules['backups'].nil?
  every :"#{schedules['backups']['every']}", at: "#{schedules['backups']['at']}" do
    command "#{bkup_script} #{db_user} #{db_name} #{bkup_folder} --exclude-schema=audit"
  end
else
  every :saturday, at: '12:30am' do
    command "#{bkup_script} #{db_user} #{db_name} #{bkup_folder} --exclude-schema=audit"
  end
end

# run log rotation
if !schedules['logrotate'].nil?
  every :"#{schedules['logrotate']['every']}", at: "#{schedules['logrotate']['at']}" do
    command "/usr/sbin/logrotate -f #{path}/config/logrotate.conf -s #{log_folder}/logrotate.log"
  end
else
  every :day, at: '11pm' do
    command "/usr/sbin/logrotate -f #{path}/config/logrotate.conf -s #{log_folder}/logrotate.log"
  end
end
