class EditSuggestionWorker
  include Sidekiq::Worker

  $api_key = Rails.application.secrets.bioportal_api_key

  # TODO: Should a random time delay go in here such that the chastisement of
  # TODO: BioPortal is somewhat mimimised?
  def perform(material_id)
    # Run Sidekiq task to call the BioPortal annotator
    # ScientificTopic.find_by_preferred_label(label)
    # suggestion = EditSuggestion
    # suggestion.materials < material
    # for each topic: suggestion.scientific_topics < topic
    material = Material.find(material_id)


    # Use long description if available, otherwise short.
    if material.long_description
      desc = material.long_description
    elsif material.short_description
      desc = material.short_description
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

    # Run the query
    # Clearly, hitting BioPortal with test fixture data would be a bit silly, but it might be useful to test somehow
    # whether this connection actually works. For now, fake data will be returned.
    if Rails.env == 'test'
      annotations << 'Bioinformatics'
    else
      begin
        response = HTTParty.get(url)
        data = JSON.parse(response.body)

        data.each do |entry|
          id = entry['annotatedClass']['@id']
          logger.info("ID: #{id}")
          if id.include? 'http://edamontology.org/topic_'
            logger.info("ENTRY: #{entry['annotatedClass']['prefLabel']}")
            annotations << entry['annotatedClass']['prefLabel']
          else
            logger.info("Material #{material.slug} matches entry #{id}.")
          end
        end
      rescue
        logger.error("Material #{material.slug} threw an exception when checking BioPortal.")
      end

    end


    # Create some topics and an edit_suggestion if some annotations were returned
    logger.info("ANNOTATION: #{annotations}")
    if annotations.length > 0
      topics = []
      annotations.each do |a|
        topic = ScientificTopic.find_by_preferred_label(a)
        if topic
          topics << topic
        end
      end
      logger.info("TOPIC: #{topics}")
      if topics
        suggestion = EditSuggestion.new(:material => material)
        topics.each do |x|
          logger.info("Created topic #{x} for #{material.slug}")
          suggestion.scientific_topics << x
        end
        suggestion.save
        logger.info("SUGGESTION: #{suggestion.inspect}")
      end
    else
      logger.info("No topics found for #{material.slug}")
    end

  end
end
