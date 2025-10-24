namespace :tess do

  # At present the records aren't logging when they were last checked.
  # This must eventually be added, perhaps with some means of marking
  # those which have failed, e.g. with a badge.
  # This is for tickets #511 and #517.

  desc 'Check material URLs for dead links'
  task check_material_urls: :environment do
    check_materials
  end

  desc 'Check event URLs for dead links'
  task check_event_urls: :environment do
    check_events
  end

  desc 'Check event and material URLs for dead links'
  task check_resource_urls: :environment do
    check_materials
    check_events
  end
end

def check_materials
  puts 'Checking material URLs'
  LinkChecker.new.check(Material)
end

def check_events
  puts 'Checking event URLs'
  LinkChecker.new.check(Event)
end
