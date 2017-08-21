require 'tess_rdf_extractors'
require 'open-uri'

class ScraperWorker
  include SidekiqStatus::Worker # Note SidekiqStatus here, so we can monitor job status

  # Args: content_provider_id, url, format
  def perform(url, format)
    format = format.to_sym

    page = open(url).read

    events = Tess::Rdf::EventExtractor.new(page, format).extract { |p| p }
    materials = Tess::Rdf::MaterialExtractor.new(page, format).extract { |p| p }

    File.open(File.join(Rails.root, 'tmp', "scrape_#{self.jid}.yml"), 'w') do |file|
      file.write({ events: events, materials: materials }.to_yaml)
    end
  end

end
