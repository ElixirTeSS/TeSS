# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!


require 'oai'
class TrainingProvider < OAI::Provider::Base
  repository_name TeSS::Config.site['title']
  repository_url 'http://localhost:3000/oai-pmh'
  record_prefix 'oai:training'
  admin_email TeSS::Config.contact_email
  source_model OAI::Provider::ActiveRecordWrapper.new(Material)
  sample_id '13900' # record prefix used, so becomes oai:training:13900
end
