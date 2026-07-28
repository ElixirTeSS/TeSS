# Configure OAI-PMH library
# see comments in: https://github.com/code4lib/ruby-oai/blob/54ea6f7f5b1e2c1be5d0a7cc61cb696b5e653d8a/lib/oai/provider.rb#L98
require 'oai'
require 'uri'

class MultiModel < OAI::Provider::Model
  # represents multiple rails models in one OAI-PMH model. 
  # It assumes OAI-PMH identifiers are of the form: <model_route_key>/<id> (e.g. materials/142)

  attr_reader :model_scopes

  def initialize(model_scopes, limit = nil, timestamp_field = 'updated_at', identifier_field = 'id')
    super(limit || 3, timestamp_field, identifier_field)
    @model_scopes = model_scopes
  end

  def earliest
    model_scopes.filter_map { |scope| scope.minimum(timestamp_field) }.min || Time.at(0).utc
  end

  def latest
    model_scopes.filter_map { |scope| scope.maximum(timestamp_field) }.max || Time.at(0).utc
  end

  def sets
    model_scopes.map do |scope|
      n = scope.model.model_name
      OAI::Set.new({spec: n.route_key, name: n.plural.titleize, description: "Set of all training #{n.plural.humanize.downcase}"})
    end
  end

  # <tt>selector</tt> can be a singular id, or the symbol :all
  def find(selector, options={})
    return find_by_id(selector) unless selector == :all

    from_date = options[:from]
    if options[:resumptionToken]
      resumption_token = OAI::Provider::ResumptionToken.parse(options[:resumptionToken])
      options = resumption_token.to_conditions_hash
      from_date = Date.parse(options[:resume_at]) if options[:resume_at]
    end

    scopes = model_scopes
    scopes = scopes.select { |scope| scope.model.model_name.route_key == options[:set] } if options[:set]
    scopes = scopes.map { |scope| scope.where("#{timestamp_field} >= ?", from_date) } if from_date
    scopes = scopes.map { |scope| scope.where("#{timestamp_field} <= ?", options[:until]) } if options[:until]
    enumerators = scopes.map { |scope| scope.order(timestamp_field => :asc, id: :asc).limit(limit + 1).to_enum }

    results = []
    skipped_results = []
    skip_until = resumption_token.next_item if resumption_token&.next_item
    while results.size < limit + 1
      enumerators = enumerators.filter { |enum| enum.peek rescue false }
      break if enumerators.empty?
      # min_by returns the first minimum resulting in deterministic order if different scopes have the same timestamp.
      min_enum = enumerators.min_by { |enum| enum.peek.send(timestamp_field) }
      result = min_enum.next
      if skip_until && result.oai_identifier == skip_until
        skip_until = nil
      end
      if skip_until && result.send(timestamp_field) > from_date
        # don't miss results in case skip_until item is not found
        skip_until = nil
        results.concat(skipped_results)
      end
      if skip_until
        skipped_results << result
      else
        results << result
      end
    end
    return results if results.size <= limit

    next_item = results.pop
    # Resumption token follows dual approach with coarse skip to resume_at and precise skip to next_item.
    resumption_token = OAI::Provider::ResumptionToken.new(options.merge({
      next_item: next_item.oai_identifier, resume_at: next_item.send(timestamp_field).iso8601
    }))
    return OAI::Provider::PartialResult.new(results, resumption_token)
  end

  private

  def find_by_id(selector)
    route_key, id = selector.to_s.split('/', 2)
    scope = model_scopes.find { |s| s.model.model_name.route_key == route_key }
    return nil unless scope

    scope.find_by(id: id)
  end
end

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
