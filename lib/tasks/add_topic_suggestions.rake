namespace :tess do
  task add_topic_suggestions: :environment do
    [Material, Event, Workflow].each do |klass|
      klass.find_each do |resource|
        if resource.edit_suggestion.nil?
          puts "Adding job to queue for : #{resource.slug}"
          EditSuggestionWorker.perform_in(1.minute, [resource.id, resource.class.name])
        end
      end
    end
  end
end
