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

  test 'check ingestion and validation of materials from zenodo' do
    # set config file
    config_file = 'test_ingestion_rest.yml'
    logfile = override_config config_file
    assert_equal 'rest', TeSS::Config.ingestion[:name]
    material_count = Material.all.size

    # check materials don't exist
    #m aterials = Material.where(title: 'My First Material', url: 'https://app.com/materials/material1.html')
    # assert !materials.nil?, "Pre-task: Materials search error."
    # assert_equal 0, materials.size, "Pre-task: Materials search title[My First Material] found something"

    # run task
    Rake::Task['tess:automated_ingestion'].invoke

=begin
    # check material added successfully
    materials = Material.where(title: 'My First Material', url: 'https://app.com/materials/material1.html')
    assert !materials.nil?, "Post-task: Materials search error."
    assert_equal 1, materials.size, "Post-task: materials search title[My First Material] found nothing"
    material = materials.first
    assert !material.nil?, "Post-task: first material from search title[My First Material] in nil."
    assert_equal 'My First Material', material.title, "material title not matched!"
    assert_equal 'https://app.com/materials/material1.html', material.url, "material url not matched!"
    assert !material.content_provider.nil?, "material provider is nil."
    assert_equal 'Another Portal Provider', material.content_provider.title, 'material provider not matched'
    assert_equal 'This is the first materials that we have created and shared.', material.description,
                 'material description not matched!'
    assert !material.keywords.nil?, 'material keywords is nil'
    assert_equal 3, material.keywords.size, 'material keywords count not matched.'
    assert material.keywords.include?('first'), 'material keyword[first] missing.'
    assert_equal 'support@app.com', material.contact, 'material contact not matched'
    assert_equal 'CC-BY-4.0', material.licence, 'material licence not matched'
    assert_equal 'active', material.status, 'material status not matched'
=end

    # check logfile messages
    message = 'Scraper.run: finish'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'IngestorMaterialRest: materials extracted = 3'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'IngestorMaterialRest: materials added\[2\] updated\[0\] rejected\[1\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Source URL\[https://app.com/materials.csv\] resources read\[3\] and written\[2\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message

  end

end