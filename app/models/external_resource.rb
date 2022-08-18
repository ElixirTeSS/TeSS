class ExternalResource < ApplicationRecord
  belongs_to :source, polymorphic: true
  has_one :link_monitor, as: :lcheck, dependent: :destroy

  validates :title, :url, presence: true
  validates :url, url: true

  BIOTOOLS_BASE = 'https://bio.tools'
  FAIRSHARING_BASE = 'https://fairsharing.org'

  def is_tool?
    url.starts_with?(BIOTOOLS_BASE)
  end

  def is_fairsharing?
    url.starts_with?(FAIRSHARING_BASE)
  end

  def is_generic_external_resource?
    !url.starts_with?(FAIRSHARING_BASE, BIOTOOLS_BASE)
  end

  def api_url_of_tool
    "#{BIOTOOLS_BASE}/api#{tool_id}" if is_tool?
  end

  def api_url_of_fairsharing
    if is_fairsharing?
      fairsharing_id = url.split(/\//)[-1]
      if fairsharing_id =~ /biodbcore-\d{6}/
        return "#{FAIRSHARING_BASE}/api/database/summary/#{fairsharing_id}"
      elsif fairsharing_id =~ /bsg-d\d{6}/
        return "#{FAIRSHARING_BASE}/api/database/summary/#{fairsharing_id}"
      elsif fairsharing_id =~ /bsg-s\d{6}/
        return "#{FAIRSHARING_BASE}/api/standard/summary/#{fairsharing_id}"
      elsif fairsharing_id =~ /bsg-p\d{6}/
        return "#{FAIRSHARING_BASE}/api/policy/summary/#{fairsharing_id}"
      end
    end
  end

  def failing?
    return false unless link_monitor
    link_monitor.failing?
  end

  private

  def tool_id
    URI.split(self.url)[5]
  end
end
