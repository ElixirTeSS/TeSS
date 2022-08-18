require 'tess_rdf_extractors'
require 'open-uri'

class ScraperWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker # Note Sidekiq::Status here, so we can monitor job status

  # Args: content_provider_id, url, format
  def perform(url, format)
    format = format.to_sym

    page = URI.open(url).read

    if format == :ics
      cals = Icalendar::Calendar.parse(page)
      event_params = Event.from_ical(cals.first).map { |e| e.attributes.reject { |_,v| v.blank? }}
      material_params = []
    else
      event_params = []
      material_params = []
      event_params += Tess::Rdf::EventExtractor.new(page, format).extract { |p| p }
      event_params += Tess::Rdf::CourseExtractor.new(page, format).extract { |p| p }
      material_params += Tess::Rdf::LearningResourceExtractor.new(page, format).extract { |p| p }
    end

    File.open(File.join(Rails.root, 'tmp', "scrape_#{self.jid}.yml"), 'w') do |file|
      file.write({ events: event_params, materials: material_params }.to_yaml)
    end
  end

end
