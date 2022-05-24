namespace :tess do

  $api_key = Rails.application.secrets.bioportal_api_key


  desc 'Query BioPortal for scientific topics'
  task get_topics: :environment do
    outfile = File.open('scientific_topics.csv', 'w')
    index = 1
    for material in Material.all
    #for material in Material.limit(2)

      # Don't bother if there are already some topics.
      if material.scientific_topic_names.length > 0
        puts "Material #{material.slug} has #{material.scientific_topic_names.length} topics already."
        next
      end

      # Use long description
      if material.description
        desc = material.description
      else
        next
      end

      # Query with BioPortal.
      # TODO: Limit to EDAM topics properly rather than using a hack (string comparison of @id).
      # N.B. There can be some dodgy non-ascii text in this so, hence the ascii conversion.
      # See String#encode documentation

      encoding_options = {
          :invalid           => :replace,
          :undef             => :replace,
          :replace           => '',
          :universal_newline => true
      }
      clean_desc = desc.encode(Encoding.find('ASCII'), encoding_options).gsub(/[\n#]/,'')

      url = "http://data.bioontology.org/annotator?include=prefLabel&text=#{clean_desc}&ontologies=EDAM&longest_only=false&exclude_numbers=false&whole_word_only=true&exclude_synonyms=false&apikey=#{$api_key}"

      annotations = []

      begin
        response = HTTParty.get(url)
        data = JSON.parse(response.body)

        data.each do |entry|
          id = entry['annotatedClass']['@id']
          if id.include? 'http://edamontology.org/topic_'
            annotations << entry['annotatedClass']['prefLabel']
            puts "Material #{material.slug} matches #{id}."
          else
            puts "Material #{material.slug} has non-topic match #{id}."
          end
        end
      rescue
        puts "Material #{material.slug} threw an exception when checking BioPortal."
      end

      if annotations.length > 0
        outfile.puts "#{material.slug}|#{annotations.join(',')}"
      else
        puts "No results for #{material.slug}"
      end

      puts "Last index: #{index}"
      index += 1

      sleep 10
    end
    outfile.close
  end

end