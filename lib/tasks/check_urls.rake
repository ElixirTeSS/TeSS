namespace :tess do

  # At present the records aren't logging when they were last checked.
  # This must eventually be added, perhaps with some means of marking
  # those which have failed, e.g. with a badge.
  # This is for ticket #511.

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

  #puts "Checking: #{record.id}, #{record.url}"
  if record.url
    code = get_bad_response(record.url)
    if code
      puts "#{code}|#{record.id}|#{record.url}"
    end
  end

  record.external_resources.each do |res|
    next unless res.url

    #puts "Checking (ER): #{res.id}, #{res.url}"
    code = get_bad_response(record.url)

    if code
      puts "#{code}|#{record.id}|#{record.url}|#{res.id}|#{res.url}"
    end
  end


end

def get_bad_response(url)
  user_agent = 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1'
  begin
    sleep(rand(10))
    response = HTTParty.head(url)
    #puts "#{response.code}, #{url}"
    return nil if response.code.to_s =~ /2[0-9]{2}/  # Success!
    return nil if response.code.to_s =~ /3[0-9]{2}/  # Redirection
    return response.code
  rescue EOFError => e
    puts "#{e}|#{url}"
  rescue SocketError => e
    puts "#{e}|#{url}"
  rescue Net::ReadTimeout => e
    puts "#{e}|#{url}"
  rescue StandardError => e
    puts "#{e}|#{url}"
  end
end

