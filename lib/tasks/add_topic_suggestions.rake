namespace :tess do

  task add_topic_suggestions: :environment do

    for material in Material.all #
      if material.edit_suggestion.nil?
        puts "Adding job to queue for : #{material.slug}"
        EditSuggestionWorker.perform_in(1.minute,[material.id,material.class.name])
      end
    end

    for event in Event.all #
      if event.edit_suggestion.nil?
        puts "Adding job to queue for : #{event.title}"
        EditSuggestionWorker.perform_in(1.minute,[event.id,event.class.name])
      end
    end

    for workflow in Event.all #
      if workflow.edit_suggestion.nil?
        puts "Adding job to queue for : #{workflow.title}"
        EditSuggestionWorker.perform_in(1.minute,[workflow.id,workflow.class.name])
      end
    end

  end

end