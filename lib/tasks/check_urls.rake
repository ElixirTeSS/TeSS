namespace :tess do

  # At present the records aren't logging when they were last checked.
  # This must eventually be added, perhaps with some means of marking
  # those which have failed, e.g. with a badge.
  # This is for tickets #511 and #517.

  desc 'Check material URLs for dead links'
  task check_material_urls: :environment do
    check_materials
  end

  desc 'Check event URLs for dead links'
  task check_event_urls: :environment do
    check_events
  end

  desc 'Check event and material URLs for dead links'
  task check_resource_urls: :environment do
    #check_materials
    check_events
  end
end

def check_materials
  puts 'Checking material URLs'
  Material.find_each do |mat|
    process_record(mat)
  end
end

def check_events
  puts 'Checking event URLs'
  Event.find_each do |event|
    process_record(event)
  end
end

def process_record(record)
  if record.url
    code = get_bad_response(record.url)
    if code
      puts "  #{code} - #{record.class.name} #{record.id}: #{record.url}"
      if record.link_monitor
        record.link_monitor.fail!(code)
      else
        record.create_link_monitor(url: record.url, code: code)
      end
    else
      if record.link_monitor
        record.link_monitor.success!
      end
    end
  end

  record.external_resources.each do |res|
    next unless res.url

    code = get_bad_response(res.url)

    if code
      puts "  #{code} - ExternalResource #{res.id}: #{res.url}"
      if res.link_monitor
        res.link_monitor.fail!(code)
      else
        res.create_link_monitor(url: res.url, code: code)
      end
    else
      if res.link_monitor
        res.link_monitor.success!
      end
    end
    res.save!
  end
end

# The fake return codes on an exception are so the LinkMonitor object has something
# to store as "code" which might be tracked back to a particular problem.
def get_bad_response(url)
  begin
    sleep(rand(10))
    response = HTTParty.head(url, verify: false)
    #puts "#{response.code}, #{url}"
    return nil if response.code.to_s =~ /2[0-9]{2}/  # Success!
    return nil if response.code.to_s =~ /3[0-9]{2}/  # Redirection
    return response.code
  rescue EOFError => e
    puts "  #{e.class.name}: #{e}"
    return 490
  rescue SocketError => e
    puts "  #{e.class.name}: #{e}"
    return 491
  rescue Net::ReadTimeout => e
    puts "  #{e.class.name}: #{e}"
    return 492
  rescue StandardError => e
    puts "  #{e.class.name}: #{e}"
    return 493
  end
end

