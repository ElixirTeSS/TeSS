class HttpUrlValidator < ActiveModel::EachValidator
  def self.blocked?(value)
    (TeSS::Config.blocked_domains || []).any? do |regex|
      value =~ regex
    end
  end

  def self.accessible?(value)
    begin
      uri = URI.parse(value) rescue nil
      if uri && (uri.scheme == 'http' || uri.scheme == 'https')
        PrivateAddressCheck.only_public_connections do
          res = HTTParty.get(value, { timeout: Rails.env.test? ? 1 : 5 })
          res.code == 200
        end
      end
    rescue PrivateAddressCheck::PrivateConnectionAttemptedError, Net::OpenTimeout, Net::ReadTimeout, SocketError,
      Errno::ECONNREFUSED, Errno::EHOSTUNREACH, OpenSSL::SSL::SSLError, URI::InvalidURIError
      false
    end
  end

  def validate_each(record, attribute, value)
    if value.present?
      if self.class.blocked?(value)
        record.errors.add(attribute, 'is blocked')
      elsif !self.class.accessible?(value)
        record.errors.add(attribute, 'is not accessible')
      end
    end
  end
end
