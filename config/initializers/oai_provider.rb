# Configure OAI-PMH library
# see comments in: https://github.com/code4lib/ruby-oai/blob/54ea6f7f5b1e2c1be5d0a7cc61cb696b5e653d8a/lib/oai/provider.rb#L98
require 'oai'
require 'uri'

class OAIRDF < OAI::Provider::Metadata::Format
  def initialize
    @prefix = 'rdf'
    @schema = 'http://www.openarchives.org/OAI/2.0/rdf.xsd'
    @namespace = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
    @element_namespace = 'rdf'
  end
end

class TrainingProvider < OAI::Provider::Base
  repository_name TeSS::Config.site['title']
  repository_url "#{TeSS::Config.base_url}/oai-pmh"
  record_prefix "oai:#{URI(TeSS::Config.base_url).host}"
  admin_email TeSS::Config.contact_email
  sample_id '142' # so that example id is oai:domain:142

  register_format(OAIRDF.instance)
end

Rails.application.config.after_initialize do
  TrainingProvider.source_model OAI::Provider::ActiveRecordWrapper.new(Material.where(visible: true))
rescue ActiveRecord::NoDatabaseError
  Rails.logger.debug 'There is no database yet, so the OAI-PMH endpoint is not configured.'
end
