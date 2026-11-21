# frozen_string_literal: true

require 'yaml'

module Ingestors
  module Heptraining
    class EpicTutorialsIngestor < Ingestor
      def self.config
        {
          key: 'epic_tutorials',
          title: 'ePIC Tutorials',
          category: :materials,
          user_agent: 'TeSS ePIC Tutorials ingestor'
        }
      end

      def read(url)
        @verbose = false
        response = open_url(url, raise: true)
        return unless response

        process_frontmatter(response.read)
      rescue StandardError => e
        Rails.logger.error("#{e.class}: read() failed, #{e.message}")
      end

      private

      def process_frontmatter(content)
        yaml_match = content.match(/\A---\s*\n(.*?)\n?---\s*/m)
        raise 'No YAML frontmatter found' unless yaml_match
        
        data = YAML.safe_load(yaml_match[1], permitted_classes: [Date, Time])
        tutorials = data['tutorials'] || []

        tutorials.each do |tutorial|
          process_tutorial(tutorial)
        end
      end

      def process_tutorial(tutorial)
        url = tutorial['url']
        return if url.blank?

        materials, events = fetch_from_other_ingestor(url)

        # Build external resources list from YAML
        ext_resources = (tutorial['resources'] || []).map do |res|
          next if res['url'].blank?

          kind = res['kind'].present? ? res['kind'].capitalize : nil
          title = res['label'].present? ? "#{kind} #{res['label']}" : kind
          { title: title, url: res['url'] }
        end.compact

        # Attach external resources to returned materials
        (materials + events).each do |material|
          material.external_resources ||= []
          material.external_resources.concat(ext_resources)
        end

        @materials.concat(materials)
        @events.concat(events)
      end

      def fetch_from_other_ingestor(url)
        ingestor = if github_url?(url)
                      Ingestors::GithubIngestor.new
                    elsif indico_url?(url)
                      Ingestors::IndicoIngestor.new
                    end

        return [[], []] unless ingestor

        ingestor.read(url)
        [ingestor.materials, ingestor.events]
      end

      def github_url?(url)
        uri = URI.parse(url)
        uri.host&.downcase == 'github.com' || uri.host&.downcase&.end_with?('.github.io')
      end

      def indico_url?(url)
        url.include?('indico')
      end
    end
  end
end