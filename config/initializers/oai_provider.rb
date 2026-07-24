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

module OAI::Provider::Response
  class RecordResponse < Base
    private

    # Allow for a custom identifier to be used in the record without affecting the query (which happens with `identifier_field`)
    def identifier_for(record)
      "#{provider.prefix}:#{record.respond_to?(:oai_identifier) ? record.oai_identifier : record.send(provider.model.identifier_field)}"
    end
  end
end

class TrainingProvider < OAI::Provider::Base
  repository_name TeSS::Config.site['title']
  repository_url "#{TeSS::Config.base_url}/oai-pmh"
  record_prefix "oai:#{URI(TeSS::Config.base_url).host}"
  admin_email TeSS::Config.contact_email
  sample_id 'materials/142' # so that example id is oai:domain:materials/142
  extra_description %(
     <description>
       <tess-instance xmlns="http://tesshub.org/xmlns" />
     </description>)

  register_format(OAIRDF.instance)
end
