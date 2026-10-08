module HasTestJob
  extend ActiveSupport::Concern

  def test_job_id
    Redis.new(url: TeSS::Config.redis_url).get(test_job_id_key)
  end

  def test_job_id=(job_id)
    Redis.new(url: TeSS::Config.redis_url).set(test_job_id_key, job_id)
  end

  def test_job_status
    Sidekiq::Status::status(test_job_id)
  end

  def test_in_progress?
    [:queued, :working, :retrying].include?(test_job_status)
  end

  def test_results
    file = test_results_path
    if File.exist?(file)
      YAML.load(File.read(file),
                aliases: true,
                permitted_classes: Rails.application.config.active_record.yaml_column_permitted_classes)
    else
      nil
    end
  end

  def test_results=(results)
    File.open(test_results_path, 'w') do |file|
      file.write(deep_hashify(results).to_yaml)
    end
  end

  class_methods do
    def get_test_resource(type, params, **extras)
      klass = type.classify.constantize
      controller = "#{klass.name.pluralize}Controller".constantize
      c = controller.new
      # No request/warden is available for this synthetic controller.
      c.define_singleton_method(:current_user) { nil }
      c.params = { klass.model_name.param_key => params }
      safe_params = c.send("#{klass.model_name.param_key}_params")
      # Extras such as `content_provider` only apply to some resource types.
      extras = extras.select { |key, _| klass.method_defined?("#{key}=") }
      klass.new(safe_params.merge(extras))
    end
  end

  private

  def test_job_id_key
    "#{model_name.singular}:#{id}:test_job_id"
  end

  def test_results_path
    path_id = Rails.env.test? ? "fakeid_#{model_name.singular}_#{id}" : test_job_id
    dir = Rails.root.join('tmp', 'source_test_results')
    dir.mkpath
    dir.join("test_results_#{path_id}.yml")
  end

  def deep_hashify(params, nested: false)
    if params.respond_to?(:attributes) && params.class.respond_to?(:reflect_on_all_associations)
      hash = nested ? params.attributes : params.attributes.symbolize_keys
      params.class.reflect_on_all_associations(:has_many).each do |association|
        next unless params.association(association.name).loaded?

        hash[association.name] = params.public_send(association.name).map { |record| deep_hashify(record, nested: true) }
      end
      return hash.transform_values { |value| deep_hashify(value, nested: nested) }
    end

    params = params.to_h if params.is_a?(OpenStruct) || params.is_a?(ActionController::Parameters)

    if params.is_a?(Hash)
      params.transform_values { |v| deep_hashify(v) }
    elsif params.is_a?(Array)
      params.map { |p| deep_hashify(p) }
    else
      params
    end
  end
end
