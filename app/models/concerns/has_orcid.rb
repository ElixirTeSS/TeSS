module HasOrcid
  extend ActiveSupport::Concern

  included do
    auto_strip_attributes :orcid
    before_validation :normalize_orcid
  end

  def orcid_url
    return nil if orcid.blank?
    "#{OrcidValidator::ORCID_PREFIX}#{orcid}"
  end

  def normalize_orcid
    return if orcid.blank?
    self.orcid = orcid.strip.sub(OrcidValidator::ORCID_DOMAIN_REGEX, '')
  end
end
