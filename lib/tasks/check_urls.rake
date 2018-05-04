namespace :tess do

  # At present the records aren't logging when they were last checked.
  # This must eventually be added, perhaps with some means of marking
  # those which have failed, e.g. with a badge.
  # This is for tickets #511 and #517.

  desc 'Check all URLs for materials'
  task check_material_urls: :environment do
    Material.all.each do |mat|
      process_record(mat)
    end
  end

  desc 'Check all URLs for events'
  task check_event_urls: :environment do
    Event.all.each do |ev|
      process_record(ev)
    end
  end

end

def process_record(record)
  puts "Checking: #{record.id}, #{record.url}"
  if record.url
    code = get_bad_response(record.url)
    if code
      puts "#{code}|#{record.id}|#{record.url}"
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

    puts "Checking (ER): #{res.id}, #{res.url}"
    code = get_bad_response(record.url)

    if code
      puts "#{code}|#{record.id}|#{record.url}|#{res.id}|#{res.url}"
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
    record.save!
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
    puts "#{e}|#{url}"
    return 490
  rescue SocketError => e
    puts "#{e}|#{url}"
    return 491
  rescue Net::ReadTimeout => e
    puts "#{e}|#{url}"
    return 492
  rescue StandardError => e
    puts "#{e}|#{url}"
    return 493
  end
end

