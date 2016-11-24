# This script should convert the timezone from https://timezonedb.com/download
# into a YAML file so it can be used in a dropdown when selecting a timezone for an event.
# rails runner -e $ENV /path/to/convert_timezones.rb


outfile = File.open('timezones.yml','w')
id = 0

zones = IO.readlines("#{Rails.root}/scripts/timezone.csv").collect {|x| x.split(',')[1]}

zones.uniq.sort.each do |z|
  next if z =~ /[+-]/
  outfile.puts("#{id}:\n  title: #{z}")
  id = id+1
end

outfile.close

