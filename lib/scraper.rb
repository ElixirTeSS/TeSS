require 'net/http'

class Scraper
  include I18n::Base

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

  attr_reader :log_file

  def self.run(config = TeSS::Config.ingestion, log_file: nil)
    if log_file.nil?
      log_path = Rails.root.join(config[:logfile])
      log_file = log_path.open('w+')
    end

    scraper = new(**config.merge(logfile: log_file))
    scraper.run
    scraper.log_file
  end

  def initialize(name: nil, logfile: nil, loglevel: 0, default_role: 'scraper_user', username: nil, sources: [])
    @name = name
    @log_file = logfile
    @log_level = loglevel
    @default_role = default_role
    @username = username
    @sources = sources
  end

  def run
    begin
      start = Time.now
      log 'Task: automated_ingestion', 0
      log '   Started at... ' + start.strftime("%Y-%m-%d %H:%M:%s"), 0
      log t('scraper.messages.status', status: 'start'), 0
      errors = 0
      # --- started

      log "ingestion file = #{@name}", 1
      log "log level = #{@log_level}", 1

      # check user
      user = get_user
      if user.role.nil? or user.role.name != @default_role
        log t('scraper.messages.invalid', error_message: t('scraper.messages.bad_role')), 1
      end

      processed = 0

      data_sources = {
        config: @sources.map { |c| Scraper::ConfigSource.new(c.merge(user: user)) },
        database: Source.find_each
      }

      data_sources.each do |key, sources|
        source_start = Time.now
        log '', 1
        log t('scraper.messages.sources_size', sources_size: sources.size) + " (from #{key})", 1
        sources.each do |source|
          output = '<ins>**Processing Ingestion Source**</ins><br />'
          processed += 1
          log '', 1
          log t('scraper.messages.processing', source: processed.to_s), 1
          if validate_source(source)
            log t('scraper.messages.valid_source'), 2
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
          run_time = source.finished_at - source_start
          output.concat '<br />'
          output.concat "**Finished at:** #{source.finished_at.strftime '%H:%M on %A, %d %B %Y (UTC)'}<br />"
          output.concat "**Run time:** #{run_time.round(2)}s<br />"
          source.log = output
          begin
            # only update enabled sources
            source.save! if source.enabled && !source.is_a?(Scraper::ConfigSource)
          rescue StandardError => e
            log t('scraper.messages.bad_source_save', error_message: e.message), 2
          end
        end
      end

      log '', 1
      log t('scraper.messages.processed', processed: processed), 1

      # --- finished
      log t('scraper.messages.status', status: 'finish'), 0

    rescue Exception => e
      log "   Run Scraper failed with: #{e.message}", 0
      log "       #{e.backtrace[0]}", 0
    end

    # wrap up
    finish = Time.now
    log '   Finished at.. ' + finish.strftime("%Y-%m-%d %H:%M:%s"), 0
    log "   Time taken was #{(1000 * (finish.to_f - start.to_f)).round(3)} ms", 0
    log 'Done.', 0
    @log_file.rewind
    @log_file
  end

  private

  def validate_source(source)
    valid = source.valid?

    unless valid
      source.errors.each do |error|
        log t('scraper.messages.invalid', error_message: "#{error.full_message}: #{source.send(error.attribute)}"), 2
      end
    end
    valid_url = validate_url(source.url, source.token)

    valid && valid_url
  end

  def validate_url(input, token)
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
      log t('scraper.messages.invalid', error_message: "#{t('scraper.messages.url_not_accessible')}: #{input}"), 2
      result = false
    end

    result
  end

  def log(message, level)
    if @log_level == 0 or @log_level.to_i >= level.to_i
      tab = 3
      prepend = level.nil? ? '' : ' ' * (tab * level)
      @log_file.puts('   ' + prepend + message)
    end
  end

  def get_user
    user = User.find_by_username(@username)
    if user.nil?
      begin
        user = User.new
        user.username = @username
        user.role = Role.find_by_name(@default_role)
        user.password = SecureRandom.urlsafe_base64(8)
        user.authentication_token = Devise.friendly_token
        user.email = "#{user.username}@#{URI.parse(TeSS::Config.base_url).host}"
        user.processing_consent = '1'
        user.save!
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
