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

    # process each source
    processed = 0
    if config[:sources] and config[:sources].size > 0
      config[:sources].each do |source|
        processed += 1
        log '', 1
        log @messages[:processing] + processed.to_s, 1
        if validate_source(source)
          log @messages[:valid_source], 2
          begin
            ingestor = IngestorFactory.get_ingestor source[:method], source[:resource_type]
            provider = getProvider(source[:provider])
            log 'Ingestor: ' + ingestor.class.name + ': read...', 2
            read = ingestor.read source[:url]
            log 'Ingestor: ' + ingestor.class.name + ': write...', 2
            written = ingestor.write user, provider
            log "Source URL[#{source[:url]}] resources read[#{read}] and written[#{written}].", 2
          rescue Exception => e
            log 'Ingestor: ' + ingestor.class.name + ': failed with: ' + e.message, 2
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

  def self.validate_source(source)
    result = true
    # get provider
    if getProvider(source[:provider]).nil?
      log @messages[:invalid] + @messages[:provider_not_found] + source[:provider].to_s, 2
      result = false
    end
    # check url
    begin
      response = Net::HTTP.get_response(URI.parse(source[:url]))
      case response
      when Net::HTTPSuccess then true
      when Net::HTTPOK then true
      else raise 'Invalid URL'
      end
    rescue
      log @messages[:invalid] + @messages[:url_not_accessible] + source[:url].to_s, 2
      result = false
    end
    # check method
    if source[:method].nil? or !IngestorFactory.is_method_valid? source[:method]
      log @messages[:invalid] + @messages[:bad_method] + source[:method], 2
      result = false
    end

    # check resource type
    if source[:resource_type].nil? or !IngestorFactory.is_resource_valid? source[:resource_type]
      log @messages[:invalid] + @messages[:bad_resource] + source[:resource_type], 2
      result = false
    end

    # return
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
      user = User.new()
      user.username = username
      user.role = Role.find_by_name(@default_role)
      user.password = SecureRandom.urlsafe_base64(8)
      user.email = "#{username}@dresa.org.au"
      user.processing_consent = '1'
      user.save!
    end
    return user
  end

  def self.getProvider (title)
    provider = ContentProvider.find_by_title(title)
  end

end