require 'tess_rdf_extractors'
require 'open-uri'

class ScraperWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker # Note Sidekiq::Status here, so we can monitor job status

  def perform(url, format)
    format = format.to_sym

    page = URI.open(url).read

    if format == :ics
      cals = Icalendar::Calendar.parse(page)
      event_params = Event.from_ical(cals.first).map { |e| e.attributes.reject { |_,v| v.blank? }}
      material_params = []
    else
      events = Tess::Rdf::EventExtractor.new(page, format, base_uri: url).extract { |p| p }
      courses = Tess::Rdf::CourseExtractor.new(page, format, base_uri: url).extract { |p| p }
      course_instances = Tess::Rdf::CourseInstanceExtractor.new(page, format, base_uri: url).extract { |p| p }
      learning_resources = Tess::Rdf::LearningResourceExtractor.new(page, format, base_uri: url).extract { |p| p }

      event_params = deduplicate(events + courses + course_instances)
      material_params = deduplicate(learning_resources)
    end

    File.open(File.join(Rails.root, 'tmp', "scrape_#{self.jid}.yml"), 'w') do |file|
      file.write({ events: event_params, materials: material_params }.to_yaml)
    end
  end

  # If duplicate resources have been extracted, prefer ones with the most metadata.
  def deduplicate(resources)
    return [] unless resources.any?
    logger.debug "De-duplicating #{resources.count} resources"
    hash = {}
    scores = {}
    resources.each do |resource|
      logger.debug "  Considering: #{resource[:url]}"
      if hash[resource[:url]]
        score = metadata_score(resource)
        # Replace the resource if this resource has a higher metadata score
        logger.debug "    Duplicate! Comparing #{score} vs. #{scores[resource[:url]]}"
        if score > scores[resource[:url]]
          logger.debug "    Replacing resource"
          hash[resource[:url]] = resource
          scores[resource[:url]] = score
        end
      else
        logger.debug "    Not present, adding"
        hash[resource[:url]] = resource
        scores[resource[:url]] = metadata_score(resource)
      end
    end

    logger.debug "#{hash.values.count} resources after de-duplication"

    hash.values
  end

  # Score based on number of metadata fields available
  def metadata_score(resource)
    resource.values.count(&:present?)
  end
end
