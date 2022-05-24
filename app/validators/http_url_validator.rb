require 'net/http'

class HttpUrlValidator < ActiveModel::EachValidator

  def self.blocked?(value)
    blocked = (TeSS::Config.blocked_domains || []).any? do |regex|
      value =~ regex
    end
  end

  def self.accessible?(value)
    begin
      case Net::HTTP.get_response(URI.parse(value))
      when Net::HTTPSuccess then true
      else false
      end
    rescue
      false
    end

  end

  def validate_each(record, attribute, value)
    if value.present?
      record.errors.add(attribute, "is blocked") if self.class.blocked?(value)
      record.errors.add(attribute, "is not accessible") unless self.class.accessible?(value)
    end
  end

end
