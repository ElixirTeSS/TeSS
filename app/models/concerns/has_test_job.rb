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
                permitted_classes: Rails.application.config.active_record.yaml_column_permitted_classes)
    else
      nil
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
    File.join(Rails.root, 'tmp', "test_results_#{test_job_id}.yml")
  end
end
