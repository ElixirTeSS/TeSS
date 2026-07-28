Rails.configuration.after_initialize do
  if TeSS::Config.sentry_enabled?
    Sentry.init do |config|
      config.dsn = TeSS::Config._sentry_dsn
      config.breadcrumbs_logger = [:active_support_logger, :http_logger]
      config.excluded_exceptions += ['ActionController::RoutingError', 'ActiveRecord::RecordNotFound']
      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      config.before_send = lambda do |event, hint|
        # Sanitize extra data
        if event.extra
          event.extra = filter.filter(event.extra)
        end
        # Sanitize user data
        if event.user
          event.user = filter.filter(event.user)
        end
        # Sanitize context data (if present)
        if event.contexts
          event.contexts = filter.filter(event.contexts)
        end
      end
      git_rev = `git rev-parse --short HEAD`&.chomp("\n")
      config.release = git_rev if git_rev.present?
    end
    Sentry.configure_scope do |scope|
      scope.set_context('app', {
        app_name: TeSS::Config.site['title_short'],
        app_version: APP_VERSION
      })
    end
  end
end
