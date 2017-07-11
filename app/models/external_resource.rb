class ExternalResource < ActiveRecord::Base

  belongs_to :source, polymorphic: true

  validates :title, :url, presence: true
  validates :url, url: true

  BIOTOOLS_BASE = 'https://bio.tools'
  FAIRSHARING_BASE = 'https://fairsharing.org'

  def is_tool?
    return self.url.starts_with?(BIOTOOLS_BASE)
  end

  def is_fairsharing?
    return self.url.starts_with?(FAIRSHARING_BASE)
  end

  def is_generic_external_resource?
    return !self.url.starts_with?(FAIRSHARING_BASE, BIOTOOLS_BASE)
  end

  def api_url_of_tool
    if self.is_tool?
      return BIOTOOLS_BASE + '/api' + tool_id
    end
    return ''
  end

  def api_url_of_fairsharing(url)
    if self.is_fairsharing?
      fairsharing_id = url.split(/\//)[-1]
      if fairsharing_id =~ /biodbcore-\d{6}/
        return FAIRSHARING_BASE + '/api/database/summary/' + fairsharing_id
      elsif fairsharing_id =~ /bsg-s\d{6}/
        return FAIRSHARING_BASE + '/api/standard/summary/' + fairsharing_id
      elsif fairsharing_id =~ /bsg-p\d{6}/
        return FAIRSHARING_BASE + '/api/policy/summary/' + fairsharing_id
      end
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
