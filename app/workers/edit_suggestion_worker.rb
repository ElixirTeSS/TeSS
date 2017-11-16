require 'geocoder'

class EditSuggestionWorker
  include Sidekiq::Worker
  Geocoder.configure(:lookup => :nominatim)

  # TODO: Should a random time delay go in here such that the chastisement of
  # TODO: BioPortal is somewhat mimimised?
  def perform(arg_array)
    suggestible_id,suggestible_type = arg_array
    logger.debug "ID: #{suggestible_id}"
    logger.debug "TYPE: #{suggestible_type}"
    # Run Sidekiq task to call the BioPortal annotator
    # EDAM::Ontology.instance.lookup_by_name(label)
    # suggestion = EditSuggestion
    # for each topic: suggestion.scientific_topics < topic
    suggestible = suggestible_type.constantize.find(suggestible_id)
    logger.debug "OBJ: #{suggestible.inspect}"

    # Use long description if available, otherwise short.
    desc = nil
    case suggestible_type
      when 'Material'
        if suggestible.long_description
          desc = suggestible.long_description
        else
          desc = suggestible.short_description
        end
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
        :invalid           => :replace,
        :undef             => :replace,
        :replace           => '',
        :universal_newline => true
    }
    clean_desc = desc.encode(Encoding.find('ASCII'), encoding_options).gsub(/[\n#]/,'')

    api_key = Rails.application.secrets.bioportal_api_key
    url = "http://data.bioontology.org/annotator?include=prefLabel&text=#{clean_desc}&ontologies=EDAM&longest_only=false&exclude_numbers=false&whole_word_only=true&exclude_synonyms=false&apikey=#{api_key}"

    ids = []

    # Run the query
    # Clearly, hitting BioPortal with test fixture data would be a bit silly, but it might be useful to test somehow
    # whether this connection actually works. For now, fake data will be returned.
    begin
      response = HTTParty.get(url)
      data = JSON.parse(response.body)

      if data.is_a?(Hash) && data['errors']
        logger.error("BioPortal response contained errors: \n\t#{data['errors'].join("\n\t")}")
      else
        data.each do |entry|
          id = entry['annotatedClass']['@id']
          if id.include? 'http://edamontology.org/topic_'
            ids << entry['annotatedClass']['@id']
            #else
            #logger.info("Suggestible #{suggestible.inspect} matches entry #{id}.")
          end
        end
      end
    rescue => exception
      logger.error("Suggestible #{suggestible.inspect} threw an exception when checking BioPortal: #{exception}\nTrace: \n\t#{exception.backtrace.join("\n\t")}\n\nBioPortal response (#{response.code}):\n#{response.body}")
    end


    # Create some topics and an edit_suggestion if some annotations were returned
    #logger.info("ANNOTATION: #{annotations}")
    if ids.any?
      topics = []
      ids.each do |id|
        topic = EDAM::Ontology.instance.lookup(id)
        if topic
          topics << topic
        end
      end
      #logger.info("TOPIC: #{topics}")
      if topics
        suggestion = EditSuggestion.new(:suggestible_type => suggestible_type, :suggestible_id => suggestible_id)
        topics.each do |x|
          #logger.info("Added topic #{x} to #{suggestible.inspect}")
          suggestion.scientific_topic_links.build(term_uri: x.uri)
        end
        if suggestion.scientific_topics.any?
          suggestion.save
          #logger.info("Suggestion created: #{suggestion.inspect}")
        else
          logger.error("Suggestion has no topics: #{suggestion.inspect}")
        end
      end
    else
      logger.debug("No topics found for #{suggestible.inspect}")
    end

    # If this is an Event and doesn't have latitude and longitude, then these should be sought out
    # via Nominatim. There's also a nominatim.rake task to do this manually, if needed.
    if suggestible_type == 'Event'
      return if suggestible.latitude && suggestible.longitude

      locations = [
        suggestible.city,
        suggestible.county,
        suggestible.country,
        suggestible.postcode,
      ].select { |x| !x.nil? && x != '' }

      return if locations.empty?

      location = locations.reject(&:blank?).join(',')
      result = Geocoder.search(location).first

      return unless result.latitude && result.longitude

      unless suggestion
        suggestion = EditSuggestion.new(:suggestible_type => suggestible_type, :suggestible_id => suggestible_id)
      end
      suggestion.data_fields = {} if suggestion.data_fields.nil?
      suggestion.data_fields['latitude'] = result.latitude
      suggestion.data_fields['longitude'] = result.longitude
      suggestion.save!
    end
  end
end
