# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

# see comments in: https://github.com/code4lib/ruby-oai/blob/master/lib/oai/provider.rb
require 'oai'
require 'uri'

class OAIRDF < OAI::Provider::Metadata::Format
  def initialize
    @prefix = 'rdf'
    @schema = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
    @namespace = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
    @element_namespace = 'rdf'
  end
end

class PublicMaterial < Material
  default_scope { where(visible: true) }
end

class TrainingProvider < OAI::Provider::Base
  repository_name TeSS::Config.site['title']
  repository_url "#{TeSS::Config.base_url}/oai-pmh"
  record_prefix "oai:#{URI(TeSS::Config.base_url).host}"
  admin_email TeSS::Config.contact_email
  source_model OAI::Provider::ActiveRecordWrapper.new(PublicMaterial)
  sample_id '13900' # record prefix used, so becomes oai:training:13900

  register_format(OAIRDF.instance)
end
