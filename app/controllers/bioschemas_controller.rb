class BioschemasController < ApplicationController
  before_action -> { feature_enabled?('bioschemas_testing') }

  def test

  end

  def run_test
    body = nil
    if params[:url].present?
      body = fetch_url
    elsif params[:snippet].present?
      body = params[:snippet]
    else
      flash[:error] = 'Please enter a URL or snippet to test.'
    end

    respond_to do |format|
      if body
        begin
          ingestor = Ingestors::BioschemasIngestor.new
          @output = ingestor.read_content(StringIO.new(body), url: params[:url])
        rescue RDF::ReaderError
          flash[:error] = 'A parsing error occurred. Please check your document contains valid JSON-LD or HTML.'
          format.html { render :test, status: :unprocessable_entity }
        else
          format.html { render :test }
        end
      else
        format.html { render :test, status: :unprocessable_entity }
      end
    end
  end

  private

  def fetch_url
    begin
      uri = URI.parse(params[:url]) rescue nil
      if uri && (uri.scheme == 'http' || uri.scheme == 'https')
        PrivateAddressCheck.only_public_connections do
          res = HTTParty.get(uri.to_s, { timeout: 5 })
          if res.code == 200
            res.body
          else
            flash[:error] = "Could not access the given URL, status: #{res.code}"
            nil
          end
        end
      else
        flash[:error] = 'Invalid URL - Make sure the URL starts with "https://" or "http://"'
        nil
      end
    rescue PrivateAddressCheck::PrivateConnectionAttemptedError, Net::OpenTimeout, SocketError, Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH
      flash[:error] = 'Could not access the given URL.'
      nil
    end
  end

end
