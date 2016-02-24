if defined?(Rails.root.to_s) && File.exists?("#{(Rails.root.to_s)}/config/version.yml")
  APP_VERSION = App::Version.load "#{(Rails.root.to_s)}/config/version.yml"
end