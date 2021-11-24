# test/tasks/rake_task_material_ingestion.rb

require 'test_helper'

class RakeTasksMaterialIngestion < ActiveSupport::TestCase

  setup do
    #puts "setup..."
    mock_ingestions
    TeSS::Application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task['tess:automated_ingestion'].reenable
    override_config 'test_ingestion_example.yml'
    assert_equal 'production', TeSS::Config.ingestion[:name]
    TeSS::Config.dictionaries['eligibility'] = 'eligibility_dresa.yml'
    EligibilityDictionary.instance.reload
    TeSS::Config.dictionaries['event_types'] = 'event_types_dresa.yml'
    EventTypeDictionary.instance.reload
    TeSS::Config.dictionaries['licences'] = 'licences_dresa.yml'
    LicenceDictionary.instance.reload
  end

  test 'check ingestion and validation of materials from csv file' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]
    material_count = Material.all.size

    # run task
    # expect addited[1] updated[1] rejected[1]
    Rake::Task['tess:automated_ingestion'].invoke

    # check logfile messages
    message = 'IngestorMaterialCsv: materials extracted = 3'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Licence must be specified'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'IngestorMaterialCsv: materials added\[2\] updated\[0\] rejected\[1\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Source URL\[https://app.com/materials.csv\] resources read\[3\] and written\[2\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Scraper.run: finish'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end


  test 'check ingestion and updating of material from csv file' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]
    material_count = Material.all.size

    # create event
    username = 'Dale'
    user = User.find_by_username(username)
    assert !user.nil?, "Username[#{username}] not found!"

    provider_title = 'Another Portal Provider'
    provider = ContentProvider.find_by_title(provider_title)
    assert !provider.nil?, "Provider title[#{provider_title}] not found!"

    url = 'https://app.com/materials/material2.html'
    title = 'Another Material'
    description = 'default description'
    locked_fields = ['description',]

    params = { user: user, content_provider: provider, url: url, title: title, description: description,
               keywords: ['Man', 'Woman', 'Person', 'Computer', 'Window',], contact: 'Dummy Contact',
               licence: 'GPL-3.0', status: ['development',], locked_fields: locked_fields }
    material = Material.new(params)
    assert material.save!, 'New material not saved!'
    assert !material.nil?, 'New material not found!'

    assert_equal (material_count + 1), Material.all.size, "Pre-invoke: number of materials not matched!"

    # run task
    # expect addited[1] updated[1] rejected[1]
    Rake::Task['tess:automated_ingestion'].invoke

    assert_equal (material_count + 2), Material.all.size, "Post-invoke: number of materials not matched!"

    # get event (again)
    materials = Material.where(title: title, url: url, content_provider: provider)
    assert !materials.nil?, "No materials found where title[#{title}] url[#{url}] provider[#{provider.title}]"
    assert !materials.first.nil?, "First material not found!"
    updated = materials.first

    # check fields of updated material
    assert_equal url, updated.url, "Updated URL not matched!"
    assert_equal title, updated.title, "Updated title not matched!"
    assert_equal provider, updated.content_provider, "Updated provider not matched!"
    assert updated.scraper_record, 'Updated not a scraper record!'
    assert !updated.last_scraped.nil?, 'Updated last scraped is nil!'

    assert_equal 'support@app.com', updated.contact, "Updated contact not matched!"
    assert_equal 'archived', updated.status, "Updated status not matched!"
    assert_equal 'CC-BY-4.0', updated.licence, "Updated licence not matched!"
    assert_equal 2, updated.keywords.size, "Updated keywords count not matched!"
    assert updated.keywords.include?('book'), "Updated keywords missing value!"

    # check locked fields not updated
    assert_equal 1, updated.locked_fields.size, "Updated locked_fields count not matched!"
    assert updated.field_locked?(:description), "Updated field (:description) not locked!"
    assert_equal description, updated.description, "Updated description has changed!"

    # check logfile messages
    message = 'IngestorMaterialCsv: materials extracted = 3'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'IngestorMaterialCsv: materials added\[1\] updated\[1\] rejected\[1\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Source URL\[https://app.com/materials.csv\] resources read\[3\] and written\[2\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Scraper.run: finish'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end

end