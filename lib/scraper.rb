require 'net/http'
require 'ingestors/ingestor_factory'

module Scraper

  @default_role = 'scraper_user'
  @log_file = ''
  @log_level = 0

  @messages = {
    scraper: 'Scraper.run: ',
    processing: 'Processing source: ',
    processed: 'Sources processed = ',
    invalid: 'Validation error: ',
    valid_source: 'Validation passed!',
    bad_role: 'User has invalid role',
    provider_not_found: 'Provider not found: ',
    url_not_accessible: 'URL not accessible: ',
    bad_method: 'Method is invalid: ',
    bad_resource: 'Resource type is invalid: ',
    sources_size: 'Sources count = ',
    bad_source_id: 'Source id invalid: ',
    bad_source_save: 'Source save failed with: ',
    bad_source_enabled: 'Source enabled flag invalid: ',
    not_source_enabled: 'Source not enabled.',
  }

  def self.run (log_file)
    @log_file = log_file
    log @messages[:scraper] + 'start', 0
    errors = 0
    # --- started

    config = TeSS::Config.ingestion
    log "ingestion file = #{config[:name]}", 1
    @log_level = config[:loglevel].to_i unless config[:loglevel].nil?
    log "log level = #{@log_level}", 1

    # check user
    user = getUser(config[:username])
    if user.role.nil? or user.role.name != @default_role
      log @messages[:invalid] + @messages[:bad_role], 1
      errors += 1
    end

    processed = 0

    # process sources in config file
    if config[:sources] and config[:sources].size > 0
      log @messages[:sources_size] + config[:sources].size.to_s, 1
      config[:sources].each do |source|
        processed += 1
        log '', 1
        log @messages[:processing] + processed.to_s, 1
        if validate_source(source)
          log @messages[:valid_source], 2

          begin
            # get provider
            provider = ContentProvider.find_by_title source[:provider]

            # get ingestor
            ingestor = IngestorFactory.get_ingestor source[:method], source[:resource_type]

            # set token
            ingestor.token = source[:token]

            # read records
            ingestor.read source[:url]
            unless ingestor.messages.nil? or ingestor.messages.empty?
              log "Ingestor: #{ingestor.class}: read messages", 2
              ingestor.messages.each { |m| log("#{m}", 3) }
              ingestor.messages.clear
            end

            # write resources
            ingestor.write user, provider
            unless ingestor.messages.nil? or ingestor.messages.empty?
              log "Ingestor: #{ingestor.class}: write messages", 2
              ingestor.messages.each { |m| log("#{m}", 3) }
              ingestor.messages.clear
            end

            # finished up ingestor
            log "Source URL[#{source[:url]}] resources read[#{ingestor.ingested}] and written[#{(ingestor.added + ingestor.updated)}].", 2
          rescue Exception => e0
            log "Scraper failed with: #{e0.message}", 2
          end
        end
      end
    end

    # process sources online
    if Source.all
      Source.all.each do |source|
        begin
          processed += 1
          log '', 1
          log @messages[:processing] + processed.to_s, 1
          output = "<ins>**Processing Ingestion Source**</ins><br />"
          if validate_source source
            log @messages[:valid_source], 2
            output.concat "<br />"
            output.concat "**Provider:** #{source.content_provider.title}<br />"
            output.concat "<span style='url-wrap'>**URL:** #{source.url}</span><br />"
            output.concat "**Method:** #{IngestorFactory.get_method_value source.method}<br />"
            output.concat "**Resource:** #{IngestorFactory.get_resource_value source.resource_type}<br />"

            # get ingestor
            ingestor = IngestorFactory.get_ingestor source.method, source.resource_type

            # set token
            ingestor.token = source.token

            # read records
            ingestor.read source.url
            unless ingestor.messages.nil? or ingestor.messages.empty?
              output.concat "<br />"
              output.concat "**Input Process:**<br />"
              ingestor.messages.each { |m| output.concat "-  #{m}<br />" }
              ingestor.messages.clear
            end

            # write resources
            ingestor.write(user, source.content_provider)
            unless ingestor.messages.nil? or ingestor.messages.empty?
              output.concat "<br />"
              output.concat "**Output Process:**<br />"
              ingestor.messages.each { |m| output.concat "-  #{m}<br />" }
              ingestor.messages.clear
            end

            # update source
            source.records_read = ingestor.ingested
            source.records_written = (ingestor.added + ingestor.updated)
            source.resources_added = ingestor.added
            source.resources_updated = ingestor.updated
            source.resources_rejected = ingestor.rejected
            log "Source URL[#{source.url}] resources read[#{source.records_read}] and written[#{source.records_written}].", 2
          end
        rescue Exception => e1
          output.concat "<br />"
          output.concat "**Failed with:** #{e1.message}<br />"
          log "Ingestor: #{ingestor.class} failed with: #{e1.message}", 2
        ensure
          source.finished_at = Time.now
          output.concat "<br />"
          output.concat "**Finished at:** #{source.finished_at.strftime '%H:%M on %A, %d %B %Y (UTC)'}<br />"
          source.log = output
          begin
            # only update enabled sources
            source.save! unless source.enabled.nil? or !source.enabled
          rescue Exception => e2
            log @messages[:bad_source_save] + e2.message, 2
          end

        end
      end
    end

    log '', 1
    log @messages[:processed] + processed.to_s, 1

    # --- finished
    log @messages[:scraper] + 'finish', 0
  end

  private

  def self.validate_source(input)
    result = true

    if input.is_a? Source
      # validate online source
      result = false unless validate_enabled(input.enabled)
      result = false unless validate_provider(input.content_provider)
      result = false unless validate_method(input.method)
      result = false unless validate_resource(input.resource_type)
      result = false unless validate_url(input.url, input.token)
    elsif input.is_a? Hash
      # validate config file source
      result = false unless validate_id(input[:id])
      result = false unless validate_enabled(input[:enabled])
      result = false unless validate_provider(input[:provider])
      result = false unless validate_method(input[:method])
      result = false unless validate_resource(input[:resource_type])
      result = false unless validate_url(input[:url], input[:token])
    else
      # invalid unexpected source
      result = false
      log @messages[:invalid] + "source is a #{input.class}", 2
    end

    # return
    return result
  end

  def self.input_to_s(input)
    input.nil? ? '' : input.to_s
  end

  def self.validate_enabled(input)
    if input.nil? and not [true, false].include?(input)
      log @messages[:invalid] + @messages[:bad_source_enabled] + input_to_s(input), 2
      return false
    end
    if !input.nil? and input == false
      log @messages[:invalid] + @messages[:not_source_enabled], 2
      return false
    end
    true
  end

  def self.validate_id(input)
    result = true
    # check id
    if input.nil? || input.is_a?(Integer) == false
      log @messages[:invalid] + @messages[:bad_source_id] + input_to_s(input), 2
      result = false
    end
    return result
  end

  def self.validate_provider(input)
    result = true
    if input.is_a? ContentProvider
      provider = input
    else
      provider = ContentProvider.find_by_title(input) unless input.nil?
    end
    if provider.nil?
      log @messages[:invalid] + @messages[:provider_not_found] + input_to_s(input), 2
      result = false
    end
    return result
  end

  def self.validate_url(input, token)
    result = true
    eventbrite_api = 'https://www.eventbriteapi.com/v3/'
    begin
      if input.starts_with?(eventbrite_api) and not token.nil?
        response = Net::HTTP.get_response(URI.parse(input + '/events/?token=' + token))
      else
        response = Net::HTTP.get_response(URI.parse(input))
      end

      case response
      when Net::HTTPSuccess then true
      when Net::HTTPOK then true
      else raise 'Invalid URL'
      end
    rescue
      log @messages[:invalid] + @messages[:url_not_accessible] + input_to_s(input), 2
      result = false
    end
    return result
  end

  def self.validate_method(input)
    result = true
    # check method
    if input.nil? or !IngestorFactory.is_method_valid? input
      log @messages[:invalid] + @messages[:bad_method] + input_to_s(input), 2
      result = false
    end
    return result
  end

  def self.validate_resource(input)
    result = true
    if input.nil? or !IngestorFactory.is_resource_valid? input
      log @messages[:invalid] + @messages[:bad_resource] + input_to_s(input), 2
      result = false
    end
    return result
  end

  def self.log(message, level)
    if @log_level == 0 or @log_level.to_i >= level.to_i
      tab = 3
      level.nil? ? prepend = "" : prepend = " " * (tab * level)
      @log_file.puts ("   " + prepend + message)
    end
  end

  def self.getUser (username)
    user = User.find_by_username(username)
    if user.nil?
      begin
        user = User.new()
        user.username = username
        user.role = Role.find_by_name(@default_role)
        user.password = SecureRandom.urlsafe_base64(8)
        user.authentication_token = Devise.friendly_token
        user.email = "#{username}@dresa.org.au"
        user.processing_consent = '1'
        user.save
        log "User created: username[#{user.username}] role[#{user.role.name}]", 1
      rescue Exception => e
        log "User create failed with: #{e}", 1
      end
    else
      log "User found: username[#{user.username}] role[#{user.role.name}]", 1
    end
    return user
  end

end