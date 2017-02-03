namespace :tess do

  task add_topic_suggestions: :environment do

    for material in Material.all # .limit(20) # for testing
      if material.scientific_topic_names.length == 0 and material.edit_suggestion.nil?
        puts "Adding job to queue for : #{material.slug}"
        EditSuggestionWorker.perform_in(1.minute,material.id)
      end
    end

  end

end