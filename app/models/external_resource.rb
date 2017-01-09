class ExternalResource < ActiveRecord::Base

  belongs_to :source, polymorphic: true

  validates :title, :url, presence: true
  validates :url, url: true

  BIOTOOLS_BASE = 'https://bio.tools'
  BIOSHARING_BASE = 'https://biosharing.org'

  def is_tool?
    return self.url.starts_with?(BIOTOOLS_BASE)
  end

  def is_biosharing?
    return self.url.starts_with?(BIOSHARING_BASE)
  end

  def is_generic_external_resource?
    return !self.url.starts_with?(BIOSHARING_BASE, BIOTOOLS_BASE)
  end

  def api_url_of_tool
    if self.is_tool?
      return BIOTOOLS_BASE + '/api' + tool_id
    end
    return ''
  end

  private

  def tool_id
    if self.is_tool?
      return  URI.split(self.url)[5]
    end
    return ''
  end

  def self.biotools_api_base_url
    return BIOTOOLS_BASE + '/api'
  end
end
