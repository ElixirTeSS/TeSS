module Scraper

  @default_role = 'scraper_user'
  @log_file = ''

  def self.run (log_file)
    @log_file = log_file
    log "Scraper.run: start", 0
    # --- started

    config = TeSS::Config.ingestion
    log "ingestion file = #{config[:name]}", 1
    user = getUser(config[:username])

    # process each source
    processed = 0
    if config[:sources] and config[:sources].size > 0
      config[:sources].each do |source|
        # get provider
        provider = ContentProvider.find_by_slug(source[:provider])
        if provider.nil?
          log "Provider[#{source[:provider]}] not found!", 2
        else
          # process provider
          # TODO: get source from url
          #
        end
      end
    end
    log "sources processed = #{processed.to_s}", 1

    # --- finished
    log "Scraper.run: finish", 0
  end

  private

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