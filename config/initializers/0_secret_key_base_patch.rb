require 'securerandom'

module Extensions
  module SecretKeyBase
    def secret_key_base
      @secret_key_base ||
        begin
          self.secret_key_base =
            if Rails.env.local? || ENV["SECRET_KEY_BASE_DUMMY"]
              super
            else
              ENV["SECRET_KEY_BASE"] || Rails.application.credentials.secret_key_base || secret_from_file
            end
        end
    end

    # Read secret from config/secrets.yml, generate if missing.
    def secret_from_file
      file = Rails.root.join('config', 'secrets.yml')
      if file.exist?
        yaml = file.read
        secret = YAML.load(yaml, aliases: true).dig(Rails.env, 'secret_key_base')
        if secret.blank?
          lines = yaml.split("\n")
          index = lines.index { |line| line.match(/\A\s*secret_key_base:\s*# ! Set production secret here/) }
          if index
            puts 'Writing new production secret_key_base to config/secrets.yml'
            lines[index].sub!(/: \s*# ! Set production secret here/, ": #{SecureRandom.hex(64)}")
            File.write(file, lines.join("\n"))
            return secret_from_file
          end
        elsif !secret.start_with?('<%')
          return secret
        end
      end

      raise 'No secret key base found! Either set the SECRET_KEY_BASE environment variable, edit config/secrets.yml, or use Rails encrypted credentials.'
    end
  end
end

Rails::Application::Configuration.prepend Extensions::SecretKeyBase
