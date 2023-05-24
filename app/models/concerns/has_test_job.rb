# frozen_string_literal: true

module HasTestJob
  extend ActiveSupport::Concern

  def test_job_id
    Redis.new(url: TeSS::Config.redis_url).get(test_job_id_key)
  end

  def test_job_id=(job_id)
    Redis.new(url: TeSS::Config.redis_url).set(test_job_id_key, job_id)
  end

  def test_job_status
    Sidekiq::Status.status(test_job_id)
  end

  def test_in_progress?
    [:queued, :working, :retrying].include?(test_job_status)
  end

  def test_results
    file = test_results_path
    if File.exist?(file)
      YAML.safe_load(File.read(file),
                     aliases: true,
                     permitted_classes: Rails.application.config.active_record.yaml_column_permitted_classes)
    end
  end

  def test_results=(results)
    File.open(test_results_path, 'w') do |file|
      file.write(results.to_yaml)
    end
  end

  private

  def test_job_id_key
    "#{model_name.singular}:#{id}:test_job_id"
  end

  def test_results_path
    path_id = Rails.env.test? ? "fakeid_#{model_name.singular}_#{id}" : test_job_id
    File.join(Rails.root, 'tmp', "test_results_#{path_id}.yml")
  end
end
