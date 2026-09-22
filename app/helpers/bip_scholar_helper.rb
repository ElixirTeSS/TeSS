module BipScholarHelper
  require 'net/http'
  require 'cgi'
  require 'json'

  def self.fetch_score(orcid)
    return nil if orcid.blank?

    # Cache in Redis for 24 hours to prevent blocking TeSS web threads
    Rails.cache.fetch("bip_scholar_score_#{orcid}", expires_in: 24.hours, skip_nil: true) do # `skip_nil: true` to avoid caching nil and then make the widget disappear
      uri = URI("https://bip-api.imsi.athenarc.gr/scholar/scores/#{CGI.escape(orcid)}")
      
      # Use timeout to prevent hanging connections
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 3
      http.open_timeout = 2

      response = http.get(uri.request_uri)
      
      response.is_a?(Net::HTTPSuccess) ? JSON.parse(response.body) : nil
    rescue StandardError => e
      Rails.logger.error("BIP!Scholar API Error for #{orcid}: #{e.message}")
      nil
    end
  end

  def format_scholar_number(num)
    num.present? ? number_with_delimiter(num) : "—"
  end

  def parse_work_types(data)
    wt = data['work_types_num']
    if wt.is_a?(Array)
      wt
    elsif wt.is_a?(Hash)
      [
        wt['papers'], 
        wt['dataset'] || wt['datasets'], 
        wt['software'], 
        wt['other']
      ]
    else
      [nil, nil, nil, nil]
    end
  end
end