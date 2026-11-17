require 'json'
require 'rest-client'
require 'erb'
require 'uri'
require 'ostruct'

module Ingestors
  class EvitaIngestor < Ingestor
    EVITA_SETTINGS = TeSS::Config.dig(:ingestors, :evita) || {}
    GITLAB_BASE_URL = EVITA_SETTINGS[:gitlab_url].to_s.strip.chomp('/')
    GITLAB_PROJECT_PATH = EVITA_SETTINGS[:project_path].to_s.strip

    def self.config
      {
        key: 'gitlab_ingestor',
        title: 'EVITA HPC',
        category: :any,
        description: 'Ingestor for the EVITA HPC training modules',
        parameters: {}
      }
    end

    def read(_source_url)
      started_at = Time.current

      stats = {
        projects_found: 0,
        projects_processed: 0,
        materials_added: 0,
        failed_projects: []
      }

      begin
        group_path = ERB::Util.url_encode(GITLAB_PROJECT_PATH)
        api_url = "#{gitlab_api_base_url}/groups/#{group_path}/projects"

        Rails.logger.info("GitLab group projects API URI: #{api_url}")

        response = RestClient.get(
          api_url,
          {
            accept: :json,
            params: { per_page: 100, include_subgroups: true },
            user_agent: 'TeSS GitLab Ingestor'
          }
        )

        projects = JSON.parse(response.body)

        raise "Unexpected response for group #{GITLAB_PROJECT_PATH}" unless projects.is_a?(Array)

        stats[:projects_found] = projects.size

        if projects.empty?
          Rails.logger.warn("No accessible projects found in GitLab group: #{GITLAB_PROJECT_PATH}")
          return
        end

        projects.each do |project|
          project_name = project['path_with_namespace']

          Rails.logger.info("Harvesting the project: #{project_name}")

          materials_before = @materials.length

          begin
            add_material(extract_material(project))

            stats[:projects_processed] += 1
            stats[:materials_added] += @materials.length - materials_before
          rescue StandardError => e
            stats[:failed_projects] << {
              name: project_name,
              error: e.message
            }

            Rails.logger.error("Failed to harvest project #{project_name}: #{e.message}")

            raise
          end
        end
      rescue RestClient::ExceptionWithResponse => e
        Rails.logger.error("EVITA HTTP error: #{e.message}")
        raise
      rescue JSON::ParserError => e
        Rails.logger.error("EVITA returned invalid JSON: #{e.message}")
        raise
      rescue StandardError => e
        Rails.logger.error("EVITA Ingestor failed: #{e.message}\n#{e.backtrace.join("\n")}")
        raise
      ensure
        duration = (Time.current - started_at).round(2)

        Rails.logger.info(
          <<~LOG
            [EVITA] Ingestion Summary Report
            ----------------------------------------------------
              GitLab group:       #{GITLAB_PROJECT_PATH}
              Projects found:     #{stats[:projects_found]}
              Projects processed: #{stats[:projects_processed]}
              Materials added:    #{stats[:materials_added]}
              Projects failed:    #{stats[:failed_projects].size}
              Duration:           #{duration} seconds
            ----------------------------------------------------
          LOG
        )

        stats[:failed_projects].each do |failure|
          Rails.logger.error("EVITA FAILED PROJECT: #{failure[:name]} - #{failure[:error]}")
        end
      end
    end

    private

    def gitlab_api_base_url
      url = "#{GITLAB_BASE_URL}/api/v4"
      raise "Invalid GitLab API URL: #{url}" unless url.match?(%r{\Ahttps://})

      url
    end

    def extract_material(project_data)
      {
        title: project_data['name'].presence || 'EVITA Training Module',
        description: project_data['description'].presence || 'EVITA HPC training modules',
        url: project_data['web_url'],
        purl: project_data['web_url'],
        provider: 'EVITA',
        licence: project_data.dig('license', 'name') || 'CC-BY-SA-4.0',
        keywords: %w[EuroHPC EVITA HPC GPU],
        target_audience: [
          'Researchers',
          'HPC Developers',
          'Software Engineers'
        ],
        status: :active,
        material_type: 'Hands-on tutorial'
      }
    end
  end
end
