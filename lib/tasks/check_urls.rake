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
  begin
    sleep(rand(20))
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Head.new(uri, {'User-Agent' => 'Link Validity Check'})
      response = http.request request
      #puts response.code

      return nil if response.code.to_s =~ /2[0-9]{2}/  # Success!
      return nil if response.code.to_s =~ /3[0-9]{2}/  # Redirection

      return response.code
    end
  rescue EOFError => e
    puts "#{e}|#{url}"
  rescue SocketError => e
    puts "#{e}|#{url}"
  end
end

