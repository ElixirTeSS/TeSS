namespace :tess do

  $api_key = Rails.application.secrets.bioportal_api_key


  desc 'Query BioPortal for scientific topics'
  task get_topics: :environment do
    outfile = File.open('scientific_topics.csv', 'w')
    for material in Material.all

      # Don't bother if there are already some topics.
      if material.scientific_topic_names.length > 0
        puts "Material #{material.slug} has #{material.scientific_topic_names.length} topics already."
        next
      end

      # Use long description if available, otherwise short.
      if material.long_description
        desc = material.long_description
      elsif material.short_description
        desc = material.short_description
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
      clean_desc = desc.encode(Encoding.find('ASCII'), encoding_options)

      url = "http://data.bioontology.org/annotator?include=prefLabel&text=#{clean_desc}&ontologies=EDAM&longest_only=false&exclude_numbers=false&whole_word_only=true&exclude_synonyms=false&apikey=#{$api_key}"
      annotations = []

      response = HTTParty.get(url)
      data = JSON.parse(response.body)

      data.each do |entry|
        id = entry['annotatedClass']['@id']
        if id.include? 'http://edamontology.org/topic_'
          annotations << entry['annotatedClass']['prefLabel']
        else
          puts "Material #{material.slug} matches #{id}."
        end
      end

      outfile.puts "#{material.slug}|#{annotations.join(',')}"

      sleep 10
    end
    outfile.close
  end

end