$biosharing_url = 'https://biosharing.org/'

namespace :biosharing do

  desc 'Adds links to BioSharing records as external resources of materials'
  task :create_links => [:environment] do

    # Parse data file manually imported from BioSharing
    datafile = "#{Rails.root}/config/data/tess_links.csv"
    begin
      lines = IO.readlines(datafile)
    rescue
      puts "Could not open datafile: #{datafile}"
      exit 0
    end

    # Add external resources, checking first for existence
    lines.each do |line|
      bid,bname,turl = line.split(/\|/)
      tslug = turl.chomp.split(/\//)[-1]
      m = Material.find_by_slug(tslug)
      if !m.nil?
        existing = m.external_resources.find_by_url($biosharing_url + bid)
        if existing.nil?
          enew = ExternalResource.new(:title => bname, :url => $biosharing_url + bid)
          enew.save
          m.external_resources << enew
          puts "Adding link for: #{bid}/#{tslug}"
        else
          puts "Already found resources for: #{bid}/#{tslug}"
        end
      end
    end

  end
end

