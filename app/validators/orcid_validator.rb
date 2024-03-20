# frozen_string_literal: true

class OrcidValidator < ActiveModel::EachValidator
  ORCID_PREFIX = 'https://orcid.org/'
  ORCID_DOMAIN_REGEX = %r{http(s)?://orcid.org/}
  ORCID_ID_REGEX = /\A[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9,X]{4}\Z/

  def validate_each(record, attribute, value)
    return if value.nil? || valid_orcid_id?(value.sub(ORCID_DOMAIN_REGEX, ''))

    record.errors.add(attribute, options[:message] || "isn't a valid ORCID identifier")
  end

  private

  # checks the structure of the id, and whether is conforms to ISO/IEC 7064:2003
  def valid_orcid_id?(id)
    if id =~ ORCID_ID_REGEX
      id = id.delete('-')
      id[15] == orcid_checksum(id)
    else
      false
    end
  end

  # calculating the checksum according to ISO/IEC 7064:2003, MOD 11-2 ;
  # see - https://support.orcid.org/hc/en-us/articles/360006897674-Structure-of-the-ORCID-Identifier
  def orcid_checksum(id)
    total = id.chars.first(15).inject(0) { |sum, value| (sum + value.to_i) * 2 }
    remainder = total % 11
    result = (12 - remainder) % 11
    result == 10 ? 'X' : result.to_s
  end
end
