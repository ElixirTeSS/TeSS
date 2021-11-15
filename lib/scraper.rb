require 'net/http'

module Scraper

  @default_role = 'scraper_user'
  @log_file = ''

  @messages = {
    scraper: 'Scraper.run: ',
    processed: 'Sources processed = ',
    invalid: 'Validation error: ',
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
    user = getUser(config[:username])
    if user.role.nil? or user.role.name != @default_role
      log @messages[:invalid] + @messages[:bad_role], 1
      errors += 1
    end

    # process each source
    processed = 0
    if config[:sources] and config[:sources].size > 0
      config[:sources].each do |source|
        if validate_source(source)
          ingestor = Ingestors::IngestorFactory.get_ingestor source[:method], source[:resource]
          # TODO: process source
          # TODO: verify response
        end
      end
    end

    log @messages[:processed] + processed.to_s, 1

    # --- finished
    log @messages[:scraper] + 'finish', 0
  end

  private

  def self.validate_source(source)
    result = true
    # get provider
    provider = ContentProvider.find_by_title(source[:provider])
    if provider.nil?
      log @messages[:invalid] + @messages[:provider_not_found] + source[:provider].to_s, 1
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
      log @messages[:invalid] + @messages[:url_not_accessible] + source[:url].to_s, 1
      result = false
    end
    # check method
    if source[:method].nil? or !Ingestors::IngestorFactory.is_method_valid? source[:method]
      log @messages[:bad_method] + source[:method], 1
      result = false
    end

    # check resource type
    if source[:resource_type].nil? or !Ingestors::IngestorFactory.is_resource_valid? source[:resource_type]
      log @messages[:bad_resource] + source[:resource_type], 1
      result = false
    end

    # return
    return result
  end

  def self.log(message, level)
    level.nil? ? prepend = "" : prepend = " " * (2 * level)
    @log_file.puts ("   " + prepend + message)
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

end