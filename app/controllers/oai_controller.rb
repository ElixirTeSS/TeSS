# The controller for actions related to OAI-PMH
class OaiController < ApplicationController
  # codeql-suppress CSRF-Violation "CSRF token authentication causes problems with OAI-PMH POST requests and OAI-PMH POST is safe because it returns static public content"
  skip_before_action :verify_authenticity_token, only: [:index]

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
