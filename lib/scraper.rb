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

            # read records
            read, messages = ingestor.read source[:url]
            unless messages.nil? or messages.empty?
              log "Ingestor: #{ingestor.class.name}: read messages", 2
              messages.each { |m| log("#{m}", 3)}
            end


            # write resources
            processed, added, updated, messages = ingestor.write user, provider
            unless messages.nil? or messages.empty?
              log "Ingestor: #{ingestor.class.name}: write messages", 2
              messages.each { |m| log("#{m}", 3)}
            end
            log "Source URL[#{source[:url]}] resources read[#{read}] and written[#{(added + updated)}].", 2
          rescue Exception => e
            log 'Ingestor: ' + ingestor.class.name + ': failed with: ' + e.message, 2
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
          output = "### Processing Ingestion Source<br />"
          if validate_source source
            log @messages[:valid_source], 2
            output.concat "**Provider:** #{source.content_provider.title}<br />"
            output.concat "     **URL:** #{source.url}<br />"
            output.concat "  **Method:** #{IngestorFactory.get_method_value source.method}<br />"
            output.concat "**Resource:** #{IngestorFactory.get_resource_value source.resource_type}<br />"

            # get ingestor
            ingestor = IngestorFactory.get_ingestor source.method, source.resource_type

            # read resources
            source.records_read, messages = ingestor.read source.url
            unless messages.nil? or messages.empty?
              output.concat " **Input Process:**<br />" unless message.nil?
              messages.each { |m| output.concat "- #{m}"}
            end
            # write resources
            total, added, updated, messages = ingestor.write user, source.content_provider
            source.records_written = (added + updated)
            source.resources_added = added
            source.resources_updated = updated
            source.resources_rejected = (total - (added + updated))
            unless messages.nil? or messages.empty?
              output.concat "**Output Process:**<br />"
              messages.each { |m| output.concat "- #{m}<br />" }
            end
            log "Source URL[#{source.url}] resources read[#{source.records_read}] and written[#{source.records_written}].", 2
          end
        rescue Exception => e
          output.concat "**Failed with:** #{e.message}<br />"
          log 'Ingestor: ' + ingestor.class.name + ': failed with: ' + e.message, 2
        ensure
          source.finished_at = Time.now
          output.concat "**Finished at:** #{source.finished_at.strftime '%H:%M on %A, %d %B %Y (UTC)'}<br />"
          source.log = output
          begin
            source.save!
          rescue Exception => e
            log @messages[:bad_source_save] + e.message, 2
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
      result = false unless validate_provider(input.content_provider)
      result = false unless validate_url(input.url)
      result = false unless validate_method(input.method)
      result = false unless validate_resource(input.resource_type)
    elsif input.is_a? Hash
      # validate config file source
      result = false unless validate_id(input[:id])
      result = false unless validate_provider(input[:provider])
      result = false unless validate_url(input[:url])
      result = false unless validate_method(input[:method])
      result = false unless validate_resource(input[:resource_type])
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

  def self.validate_url(input)
    result = true
    begin
      response = Net::HTTP.get_response(URI.parse(input))
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