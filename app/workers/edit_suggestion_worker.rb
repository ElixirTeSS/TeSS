class EditSuggestionWorker
  include Sidekiq::Worker

  # TODO: Should a random time delay go in here such that the chastisement of
  # TODO: BioPortal is somewhat mimimised?
  def perform(arg_array)
    suggestible_id, suggestible_type = arg_array
    logger.debug "ID: #{suggestible_id}"
    logger.debug "TYPE: #{suggestible_type}"
    # Run Sidekiq task to call the BioPortal annotator
    suggestible = suggestible_type.constantize.find_by_id(suggestible_id)
    unless suggestible
      logger.debug "#{suggestible_type} #{suggestible_id} not found"
      return
    end
    logger.debug "OBJ: #{suggestible.inspect}"

    # Use long description if available, otherwise short.
    desc = nil
    case suggestible_type
    when 'Material'
      desc = suggestible.description
    when 'Event'
      desc = suggestible.description
    when 'Workflow'
      desc = suggestible.description
    end

    if desc.blank?
      logger.debug("No description provided for #{suggestible.inspect}")
      return
    end

    # Query with BioPortal.
    # TODO: Limit to EDAM topics properly rather than using a hack (string comparison of @id).
    # N.B. There can be some dodgy non-ascii text in this so, hence the ascii conversion.
    # See String#encode documentation

    encoding_options = {
      :invalid => :replace,
      :undef => :replace,
      :replace => '',
      :universal_newline => true
    }
    clean_desc = desc.encode(Encoding.find('ASCII'), **encoding_options).gsub(/[\n#]/, '')

    api_key = Rails.application.secrets.bioportal_api_key
    url = "http://data.bioontology.org/annotator?include=prefLabel&text=#{clean_desc}&ontologies=EDAM&longest_only=false&exclude_numbers=false&whole_word_only=true&exclude_synonyms=false&apikey=#{api_key}"

    suggestion = nil
    topic_uris = []
    operation_uris = []

    # Run the query
    # Clearly, hitting BioPortal with test fixture data would be a bit silly, but it might be useful to test somehow
    # whether this connection actually works. For now, fake data will be returned.
    begin
      response = HTTParty.get(url)
      data = JSON.parse(response.body)

      if data.is_a?(Hash) && (data['error'] || data['errors'])
        error = data['error'] || data['errors'].join("\n\t")
        logger.error("BioPortal response contained errors: \n\t#{error}")
      else
        data.each do |entry|
          id = entry['annotatedClass']['@id']
          if id.include? 'http://edamontology.org/topic_'
            topic_uris << entry['annotatedClass']['@id']
          elsif id.include? 'http://edamontology.org/operation_'
            operation_uris << entry['annotatedClass']['@id']
          end
        end
      end
    rescue StandardError => exception
      error = "Suggestible #{suggestible.inspect} threw an exception when checking BioPortal: #{exception}\n"+
        "Trace: \n\t#{exception.backtrace.join("\n\t")}"
      error += "\n\nBioPortal response (#{response.code}):\n#{response.body}" if response
      logger.error(error)
    end

    # Create some topics and an edit_suggestion if some annotations were returned
    #logger.info("ANNOTATION: #{annotations}")
    [[topic_uris, 'scientific_topic'], [operation_uris, 'operation']].each do |ids, type|
      if ids.any?
        terms = ids.map { |id| Edam::Ontology.instance.lookup(id) }.compact

        if terms.any?
          suggestion = suggestible.build_edit_suggestion
          terms.each do |term|
            #logger.info("Added topic #{term} to #{suggestible.inspect}")
            suggestion.ontology_term_links.build(term_uri: term.uri, field: type.pluralize)
          end
          unless suggestion.save
            logger.error("Suggestion didn't save: #{suggestion.errors.full_messages.inspect}")
          end
        end
      else
        logger.debug("No #{type.pluralize} found for #{suggestible.inspect}")
      end
    end
  end
end
