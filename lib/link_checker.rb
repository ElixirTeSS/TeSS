class LinkChecker
  def self.check(record, log: true)
    [record, *record.external_resources].each do |item|
      next if item.url.blank?
      code = bad_response(item.url, log: log)
      if code
        puts "  #{code} - #{item.class.name} #{item.id}: #{item.url}" if log
        if item.link_monitor
          item.link_monitor.fail!(code)
        else
          item.create_link_monitor(url: item.url, code: code)
        end
      else
        if item.link_monitor
          item.link_monitor.success!
        end
      end
    end
  end

  # The fake return codes on an exception are so the LinkMonitor object has something
  # to store as "code" which might be tracked back to a particular problem.
  def self.bad_response(url, log: true)
    begin
      host = URI.parse(url).host rescue nil
      if @prev_host == host
        n = rand(4) + 1 # Add some delay between requests to the same host to prevent flooding
        sleep(n)
      end
      @prev_host = host
      code = HTTParty.head(url, verify: false).code
      code = get_code(url) if code == 400 || code == 405 # Try a GET if HEAD not allowed (or generic 400 error)
      return nil if code >= 200 && code < 400 # Success or redirects are OK
      return code
    rescue EOFError => e
      puts "  #{e.class.name}: #{e}" if log
      return 490
    rescue SocketError => e
      puts "  #{e.class.name}: #{e}" if log
      return 491
    rescue Timeout::Error => e
      puts "  #{e.class.name}: #{e}" if log
      return 492
    rescue StandardError => e
      puts "  #{e.class.name}: #{e}" if log
      return 493
    end
  end

  # Gets a response code using a GET request, for the case where HEAD is not supported.
  def self.get_code(url, redirect_limit: 5, open_timeout: 5, read_timeout: 5, use_range: true)
    raise StandardError, 'too many redirects' if redirect_limit <= 0

    uri = URI(url)

    # Prepare the HTTP connection
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = open_timeout
    http.read_timeout = read_timeout
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    # Build GET request (not HEAD)
    req = Net::HTTP::Get.new(uri)
    req['Range'] = 'bytes=0-0' if use_range # fetch just the first byte if supported

    http.start do |connection|
      connection.request(req) do |res|
        case res
        when Net::HTTPRedirection
          location = res['location']
          new_uri = URI.join(uri, location).to_s
          return get_code(new_uri,
                          redirect_limit: redirect_limit - 1,
                          open_timeout: open_timeout,
                          read_timeout: read_timeout,
                          use_range: use_range)
        else
          code = res.code.to_i
          # Do not call res.read_body — we don't want to download the content
          return code
        end
      end
    end
  end
end
