# frozen_string_literal: true

class HttpUrlValidator < ActiveModel::EachValidator
  def self.blocked?(value)
    (TeSS::Config.blocked_domains || []).any? do |regex|
      value =~ regex
    end
  end

  def self.accessible?(value)
    uri = begin
      URI.parse(value)
    rescue StandardError
      nil
    end
    if uri && (uri.scheme == 'http' || uri.scheme == 'https')
      PrivateAddressCheck.only_public_connections do
        res = HTTParty.get(value, { timeout: Rails.env.test? ? 1 : 5 })
        res.code == 200
      end
    end
  rescue PrivateAddressCheck::PrivateConnectionAttemptedError, Net::OpenTimeout, SocketError, Errno::ECONNREFUSED,
         Errno::EHOSTUNREACH
    false
  end

  def validate_each(record, attribute, value)
    return unless value.present?

    if self.class.blocked?(value)
      record.errors.add(attribute, 'is blocked')
    elsif !self.class.accessible?(value)
      record.errors.add(attribute, 'is not accessible')
    end
  end
end
