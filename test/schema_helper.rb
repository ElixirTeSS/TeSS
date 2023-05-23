# frozen_string_literal: true

# Hackery from:
# https://github.com/interagent/committee/blob/master/lib/committee/test/methods.rb
# to allow us to validate against the 2 different API schemas.
module SchemaHelper
  class CommitteeRequestObject
    delegate_missing_to :@request

    def initialize(request)
      @request = request
    end

    def path
      # Chomp the `.json_api` because I can't see an easy way of making the test request JSON-API via the `Accept` header
      # and committee won't match the `<something>.json_api` paths against the spec.
      URI.parse(@request.original_fullpath).path.chomp('.json_api')
    end

    alias path_info path

    def request_method
      @request.env['action_dispatch.original_request_method'] || @request.request_method
    end
  end

  def assert_valid_json_api_response(expected_status = 200)
    assert_valid_json_response(current_schema_validator, current_committee_options, expected_status)
  end

  def assert_valid_legacy_json_response(expected_status = 200)
    assert_valid_json_response(legacy_schema_validator, legacy_committee_options, expected_status)
  end

  def assert_valid_json_response(validator, options, expected_status = nil)
    unless validator.link_exist?
      response = "`#{committee_request_object.request_method} #{committee_request_object.path_info}` undefined in schema (prefix: #{options[:prefix].inspect})."
      raise Committee::InvalidResponse, response
    end

    status, headers, body = committee_response_data

    if expected_status.nil?
      Committee.warn_deprecated('Pass expected response status code to check it against the corresponding schema explicitly.')
    elsif expected_status != status
      response = "Expected `#{expected_status}` status code, but it was `#{status}`."
      raise Committee::InvalidResponse, response
    end

    valid = Committee::Middleware::ResponseValidation.validate?(status, options.fetch(:validate_success_only, false))

    validator.response_validate(status, headers, [body], true) if valid
  end

  def committee_request_object
    @request_object ||= CommitteeRequestObject.new(@request)
  end

  def committee_response_data
    [@response.status, @response.headers, @response.body]
  end

  def current_committee_options
    @current_committee_options ||= {
      schema: Committee::Drivers.load_from_file('public/api/definitions/tess.yml'),
      query_hash_key: 'rack.request.query_hash',
      parse_response_by_content_type: false
    }
  end

  def legacy_committee_options
    @legacy_committee_options ||= {
      schema: Committee::Drivers.load_from_file('public/api/definitions/tess_legacy.yml'),
      query_hash_key: 'rack.request.query_hash',
      parse_response_by_content_type: false
    }
  end

  def current_schema
    @current_schema ||= Committee::Middleware::Base.get_schema(current_committee_options)
  end

  def legacy_schema
    @legacy_schema ||= Committee::Middleware::Base.get_schema(legacy_committee_options)
  end

  def current_router
    @current_router ||= current_schema.build_router(current_committee_options)
  end

  def legacy_router
    @legacy_router ||= legacy_schema.build_router(legacy_committee_options)
  end

  def current_schema_validator
    @current_schema_validator ||= current_router.build_schema_validator(committee_request_object)
  end

  def legacy_schema_validator
    @legacy_schema_validator ||= legacy_router.build_schema_validator(committee_request_object)
  end
end
