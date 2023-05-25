# frozen_string_literal: true

$fairsharing_url = 'https://fairsharing.org/'

namespace :fairsharing do
  desc 'Adds links to FAIRsharing records as external resources of materials'
  task create_links: [:environment] do
    # Parse data file manually imported from FAIRsharing
    datafile = "#{Rails.root}/config/data/tess_links.csv"
    begin
      lines = File.readlines(datafile)
    rescue StandardError
      puts "Could not open datafile: #{datafile}"
      exit 0
    end

    # Add external resources, checking first for existence
    lines.each do |line|
      bid, bname, turl = line.split(/\|/)
      tslug = turl.chomp.split(%r{/})[-1]
      m = Material.find_by(slug: tslug)
      next if m.nil?

      existing = m.external_resources.find_by(url: $fairsharing_url + bid)
      if existing.nil?
        enew = ExternalResource.new(title: bname, url: $fairsharing_url + bid)
        enew.save
        m.external_resources << enew
        puts "Adding link for: #{bid}/#{tslug}"
      else
        puts "Already found resources for: #{bid}/#{tslug}"
      end
    end
  end
end
