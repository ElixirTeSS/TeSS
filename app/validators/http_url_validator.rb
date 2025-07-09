class HttpUrlValidator < ActiveModel::EachValidator
  def blocked?(value)
    (TeSS::Config.blocked_domains || []).any? do |regex|
      value =~ regex
    end
  end

  def accessible?(value)
    code = nil
    begin
      uri = URI.parse(value) rescue nil
      if uri && (uri.scheme == 'http' || uri.scheme == 'https')
        PrivateAddressCheck.only_public_connections do
          res = HTTParty.get(value, { timeout: Rails.env.test? ? 1 : 5 })
          code = res.code
        end
      end
    rescue PrivateAddressCheck::PrivateConnectionAttemptedError
      return false
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError,
      Errno::ECONNREFUSED, Errno::EHOSTUNREACH, OpenSSL::SSL::SSLError, URI::InvalidURIError
      code = 999
    end
    options[:allow_inaccessible] || code == 200
  end

  def validate_each(record, attribute, value)
    if value.present?
      if blocked?(value)
        record.errors.add(attribute, 'is blocked')
      elsif !accessible?(value)
        record.errors.add(attribute, 'is not accessible')
      end
    end
  end
end
