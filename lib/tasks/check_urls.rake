namespace :tess do

  # At present the records aren't logging when they were last checked.
  # This must eventually be added, perhaps with some means of marking
  # those which have failed, e.g. with a badge.
  # This is for tickets #511 and #517.

  desc 'Check material URLs for dead links'
  task check_material_urls: :environment do
    puts 'Checking material URLs'
    LinkChecker.new.check(Material)
  end

  desc 'Check event URLs for dead links'
  task check_event_urls: :environment do
    puts 'Checking event URLs'
    LinkChecker.new.check(Event)
  end

  desc 'Check event and material URLs for dead links'
  task check_resource_urls: :environment do
    lc = LinkChecker.new

    puts 'Checking material URLs'
    lc.check(Material)

    puts 'Checking event URLs'
    lc.check(Event)
  end
end
