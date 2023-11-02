class BioschemasController < ApplicationController
  def test
    if params[:url].present?
      body = fetch_url
    else
      body = params[:snippet]
    end

    respond_to do |format|
      if body
        @ingestor = Ingestors::BioschemasIngestor.new
        @output = @ingestor.read_content(StringIO.new(body), url: params[:url])
      end
      format.html
    end
  end

  private

  def fetch_url
    begin
      uri = URI.parse(params[:url]) rescue nil
      if uri && (uri.scheme == 'http' || uri.scheme == 'https')
        PrivateAddressCheck.only_public_connections do
          res = HTTParty.get(uri.to_s, { timeout: 5 })
          res.body
        end
      else
        flash[:error] = 'Invalid URL - Make sure the URL starts with "https://" or "http://"'
        nil
      end
    rescue PrivateAddressCheck::PrivateConnectionAttemptedError, Net::OpenTimeout, SocketError, Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH
      flash[:error] = 'Could not access the given URL'
      nil
    end
  end
end
