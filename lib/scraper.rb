require 'net/http'

module Scraper
  # Class to represent a ingestion source loaded from ingestion.yml
  class ConfigSource < Source
    before_save -> { throw :abort } # Prevent saving to database
    validate :provider_exists
    attr_reader :provider

    def provider=(title)
      @provider = title
      self.content_provider = ContentProvider.find_by(title: @provider)
    end

    def provider_exists
      unless self.content_provider
        errors.add(:provider, 'not found')
        errors.delete(:content_provider)
      end
    end
  end

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
    url_not_accessible: 'URL not accessible: ',
    sources_size: 'Sources count = ',
    bad_source_save: 'Source save failed with: ',
    not_source_enabled: 'Source not enabled.'
  }

  def self.run(log_file)
    @log_file = log_file
    log @messages[:scraper] + 'start', 0
    errors = 0
    # --- started

    config = TeSS::Config.ingestion
    log "ingestion file = #{config[:name]}", 1
    @log_level = config[:loglevel].to_i unless config[:loglevel].nil?
    log "log level = #{@log_level}", 1

    # check user
    user = get_user(config[:username])
    if user.role.nil? or user.role.name != @default_role
      log @messages[:invalid] + @messages[:bad_role], 1
      errors += 1
    end

    processed = 0

    data_sources = {
      config: (config[:sources] || []).map { |c| Scraper::ConfigSource.new(c.merge(user: user)) },
      database: Source.find_each
    }

    data_sources.each do |key, sources|
      log '', 1
      log @messages[:sources_size] + sources.size.to_s + " (from #{key})", 1
      sources.each do |source|
        output = '<ins>**Processing Ingestion Source**</ins><br />'
        processed += 1
        log '', 1
        log @messages[:processing] + processed.to_s, 1
        if validate_source(source)
          log @messages[:valid_source], 2
          output.concat '<br />'
          output.concat "**Provider:** #{source.content_provider.title}<br />"
          output.concat "<span style='url-wrap'>**URL:** #{source.url}</span><br />"
          output.concat "**Method:** #{source.ingestor_title}<br />"

          # get ingestor
          ingestor = Ingestors::IngestorFactory.get_ingestor(source.method)

          # set token
          ingestor.token = source.token

          # read records
          ingestor.read(source.url)
          unless ingestor.messages.nil? or ingestor.messages.empty?
            output.concat '<br />'
            output.concat '**Input Process:**<br />'
            ingestor.messages.each { |m| output.concat "-  #{m}<br />" }
            ingestor.messages.clear
          end

          # write resources
          ingestor.write(user, source.content_provider)
          unless ingestor.messages.nil? or ingestor.messages.empty?
            output.concat '<br />'
            output.concat '**Output Process:**<br />'
            ingestor.messages.each { |m| output.concat "-  #{m}<br />" }
            ingestor.messages.clear
          end

          # update source
          source.records_read = ingestor.ingested
          source.records_written = (ingestor.added + ingestor.updated)
          source.resources_added = ingestor.added
          source.resources_updated = ingestor.updated
          source.resources_rejected = ingestor.rejected
          log "Source URL[#{source.url}] resources read[#{source.records_read}]" +
                ", added[#{source.resources_added}]" +
                ", updated[#{source.resources_updated}]" +
                ", rejected[#{source.resources_rejected}]", 2
        end
      rescue StandardError => e
        output.concat '<br />'
        output.concat "**Failed with:** #{e.message}<br />"
        log "Ingestor: #{ingestor.class} failed with: #{e.message}\t#{e.backtrace[0]}", 2
      ensure
        source.finished_at = Time.now
        output.concat '<br />'
        output.concat "**Finished at:** #{source.finished_at.strftime '%H:%M on %A, %d %B %Y (UTC)'}<br />"
        source.log = output
        begin
          # only update enabled sources
          source.save! if source.enabled && !source.is_a?(Scraper::ConfigSource)
        rescue StandardError => e
          log @messages[:bad_source_save] + e.message, 2
        end
      end
    end

    log '', 1
    log @messages[:processed] + processed.to_s, 1

    # --- finished
    log @messages[:scraper] + 'finish', 0
  end

  def self.validate_source(source)
    valid = source.valid?

    unless valid
      source.errors.each do |error|
        log "#{@messages[:invalid]}#{error.full_message}: #{source.send(error.attribute)}", 2
      end
    end
    valid_url = validate_url(source.url, source.token)

    valid && valid_url
  end

  def self.input_to_s(input)
    input.nil? ? '' : input.to_s
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

  def self.log(message, level)
    if @log_level == 0 or @log_level.to_i >= level.to_i
      tab = 3
      prepend = level.nil? ? '' : ' ' * (tab * level)
      @log_file.puts('   ' + prepend + message)
    end
  end

  def self.get_user(username)
    user = User.find_by_username(username)
    if user.nil?
      begin
        user = User.new
        user.username = username
        user.role = Role.find_by_name(@default_role)
        user.password = SecureRandom.urlsafe_base64(8)
        user.authentication_token = Devise.friendly_token
        user.email = "#{username}@#{URI.parse(TeSS::Config.base_url).host}"
        user.processing_consent = '1'
        user.save
        log "User created: username[#{user.username}] role[#{user.role.name}]", 1
      rescue Exception => e
        log "User create failed with: #{e}", 1
      end
    else
      log "User found: username[#{user.username}] role[#{user.role.name}]", 1
    end
    user
  end
end
