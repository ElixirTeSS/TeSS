class OaiController < ApplicationController
  # This view only returns static public content and CSRF token authentication causes problems with OAI-PMH POST requests
  skip_before_action :verify_authenticity_token

  # GET /oai-pmh
  def index
    provider = TrainingProvider.new
    response = provider.process_request(oai_params.to_h)

    # add XSLT prefix
    response.sub!(/<\?xml[^>]+\?>/, "\\0\n<?xml-stylesheet type=\"text/xsl\" href=\"/oai2xhtml.xsl\"?>")

    render body: response, content_type: 'text/xml'
  end

  private

  def oai_params
    params.permit(:verb, :identifier, :metadataPrefix, :set, :from, :until, :resumptionToken)
  end
end
