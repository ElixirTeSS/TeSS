# frozen_string_literal: true

Rails.configuration.after_initialize do
  if TeSS::Config.sentry_enabled?
    Sentry.init do |config|
      config.dsn = TeSS::Config._sentry_dsn
      config.breadcrumbs_logger = %i[active_support_logger http_logger]
      config.excluded_exceptions += ['ActionController::RoutingError', 'ActiveRecord::RecordNotFound']
      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      config.before_send = lambda do |event, _hint|
        filter.filter(event.to_hash)
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
