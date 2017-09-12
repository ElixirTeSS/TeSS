require 'tess_rdf_extractors'
require 'open-uri'

class ScraperWorker
  include SidekiqStatus::Worker # Note SidekiqStatus here, so we can monitor job status

  # Args: content_provider_id, url, format
  def perform(url, format)
    format = format.to_sym

    page = open(url).read

    if format == :ics
      cals = Icalendar::Calendar.parse(page)
      event_params = Event.from_ical(cals.first).map { |e| e.attributes.reject { |_,v| v.blank? }}
      material_params = []
    else
      event_params = Tess::Rdf::EventExtractor.new(page, format).extract { |p| p }
      material_params = Tess::Rdf::MaterialExtractor.new(page, format).extract { |p| p }
    end

    File.open(File.join(Rails.root, 'tmp', "scrape_#{self.jid}.yml"), 'w') do |file|
      file.write({ events: event_params, materials: material_params }.to_yaml)
    end
  end

end
