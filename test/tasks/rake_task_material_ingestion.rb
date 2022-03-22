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

  teardown do
    # delete materials
    delete_material'My First Material', 'https://app.com/materials/material1.html'
    delete_material 'Another Material', 'https://app.com/materials/material2.html'
  end

  test 'check ingestion of materials from csv file' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]
    material_count = 11
    assert_equal material_count, Material.all.size,
                 'Pre-invoke: Material count not matched.'

    # run  - expect added[2] updated[0] rejected[1]
    Rake::Task['tess:automated_ingestion'].invoke

    # check totals
    assert_equal (material_count + 2), Material.all.size,
                 'Post-invoke: Material count not matched.'

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

  test 'validate ingestion of first material from csv file' do
    title = 'My First Material'
    url = 'https://app.com/materials/material1.html'

    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]
    material_count = 11
    assert_equal material_count, Material.all.size, 'Pre-invoke: Material count not matched'

    # check materials don't exist
    materials = Material.where(title: title, url: url)
    assert !materials.nil?, "Pre-task: Materials search error."
    assert_equal 0, materials.size, "Pre-task: Materials search title[#{title}] found something"

    # run task - expect added[2] updated[0] rejected[1]
    Rake::Task['tess:automated_ingestion'].invoke

    # check material added successfully
    assert_equal (material_count + 2), Material.all.size, 'Post-invoke: Material count not matched.'
    materials = Material.where(title: title, url: url)
    assert !materials.nil?, "Post-task: Materials search error."
    assert_equal 1, materials.size, "Post-task: materials search title[#{title}] found nothing"
    material = materials.first
    assert !material.nil?, "Post-task: first material from search title[#{title}] in nil."
    assert_equal title, material.title, "material title not matched!"
    assert_equal url, material.url, "material url not matched!"
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
    assert_equal 0, material.authors.size, 'material authors count not matched.'
    assert_equal 1, material.contributors.size, 'material contributors count not matched.'
    assert material.contributors.include?('Sam Smiths'), 'material contributor[Sam Smiths] missing.'
    assert !material.contributors.include?('Wily Coyote'), 'material contributor[Wily Coyote] exists.'
    assert !material.doi.nil?, 'material doi is nil'
    assert_equal '10.5281/zenodo.5778051', material.doi, 'material doi not matched.'
  end

  test 'validate ingestion of another material from csv file' do
    title = 'Another Material'
    url = 'https://app.com/materials/material2.html'

    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]
    material_count = 11
    assert_equal material_count, Material.all.size, 'Pre-invoke: Material count not matched'

    # check materials don't exist
    materials = Material.where(title: title, url: url)
    assert !materials.nil?, "Pre-task: Materials search error."
    assert_equal 0, materials.size, "Pre-task: Materials search title[#{title}] found!"

    # run task - expect added[2] updated[0] rejected[1]
    Rake::Task['tess:automated_ingestion'].invoke

    # check material added successfully
    assert_equal (material_count + 2), Material.all.size, 'Post-invoke: Material count not matched.'
    materials = Material.where(title: title, url: url)
    assert !materials.nil?, "Post-task: Materials search error."
    assert_equal 1, materials.size, "Post-task: materials search title[#{title}] found nothing"
    material = materials.first
    assert !material.nil?, "Post-task: material from search title[#{title}] in nil."
    assert !material.contact.nil?, "#{title}: contact is nil."
    assert_equal 'user@provider.portal', material.contact, "#{title}: contact should match default (content_provider)."
    assert !material.doi.nil?, "#{title}: doi is nil."
    assert_equal 'https://doi.org/10.5281/zenodo.5778051', material.doi, "#{title}: doi not matched."
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

    assert_equal (material_count + 1), Material.all.size, "Pre-invoke: number of materials not matched"

    # run task - expect added[1] updated[1] rejected[1]
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

    assert_equal 'user@provider.portal', updated.contact, "Updated contact not matched!"
    assert_equal 'archived', updated.status, "Updated status not matched!"
    assert_equal 'CC-BY-4.0', updated.licence, "Updated licence not matched!"
    assert_equal 2, updated.keywords.size, "Updated keywords count not matched!"
    assert updated.keywords.include?('book'), "Updated keywords missing value!"
    assert_equal 2, updated.authors.size, "Updated authors count not matched! ... #{updated.authors.inspect}"
    assert updated.authors.include?('Steven Smith'), "Updated authors[Steven Smith] missing!"
    assert updated.authors.include?('Sam Harpic'), "Updated authors[Sam Harpic] missing!"
    assert_equal 0, updated.contributors.size, "Updated contributors count not matched!"

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

  private

  def delete_material(title, url)
    materials = Material.where(title: title, url: url)
    materials.first.delete if !materials.nil? and materials.size > 0
  end
end