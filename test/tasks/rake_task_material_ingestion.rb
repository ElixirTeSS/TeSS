# test/tasks/rake_task_material_ingestion.rb

require 'test_helper'

class RakeTasksMaterialIngestion < ActiveSupport::TestCase

  setup do
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
    delete_material 'My First Material', 'https://app.com/materials/material1.html'
    delete_material 'Another Material', 'https://app.com/materials/material2.html'
  end

  test 'check ingestion of materials from csv file' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]

    assert_difference 'Material.count', 2 do
      freeze_time(stub_time = Time.new(2022)) do ||
        # run  - expect added[2] updated[0] rejected[1]
        Rake::Task['tess:automated_ingestion'].invoke
      end
    end

    # check logfile messages
    message = 'Licence must be specified'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'materials processed\[3\] added\[2\] updated\[0\] rejected\[1\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Source URL\[https://app.com/materials.csv\] resources read\[3\] and written\[2\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Scraper.run: finish'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end

  test 'validate ingestion of first material from csv file' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]

    # check test material doesn't exist
    title = 'My First Material'
    url = 'https://app.com/materials/material1.html'
    assert get_material(title, url).nil?

    # expect to add 2 materials
    assert_difference 'Material.count', 2 do
      freeze_time(stub_time = Time.new(2022)) do ||
        # run task - expect added[2] updated[0] rejected[1]
        Rake::Task['tess:automated_ingestion'].invoke
      end
    end

    # check material added successfully with no errors
    material = get_material title, url
    refute material.nil?, "material title[#{title}] not found."
    refute material.errors.nil?
    assert material.errors.empty?, "material title[#{title}] has errors"

    # check required attributes
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

    # check optional attributes
    # DOI
    refute material.doi.nil?, 'material doi is nil'
    assert_equal '10.5281/zenodo.5778051', material.doi, 'material doi not matched.'
    # version
    refute material.version.nil?, 'material version is nil'
    assert_equal '1.1', material.version, 'material version not matched.'
    # published
    refute material.date_published.nil?, 'material date_published is nil'
    assert_equal Date.new(2021,3,14), material.date_published, 'material date_published not matched.'
    # modified
    refute material.date_modified.nil?, 'material date_modified is nil'
    assert_equal Date.new(2021,9,21), material.date_modified, 'material date_modified not matched.'
    # competency
    refute material.difficulty_level.nil?, 'material difficulty_level is nil?'
    refute_equal 'notspecified', material.difficulty_level, 'material difficulty_level is notspecified.'
    assert_equal 'beginner', material.difficulty_level, 'material difficulty_level not matched.'
    # authors
    refute material.authors.nil?, 'material authors is nil'
    assert_equal 0, material.authors.size, 'material authors count not matched.'
    # contributors
    refute material.contributors.nil?, 'material contributors is nil'
    assert_equal 1, material.contributors.size, 'material contributors count not matched.'
    assert material.contributors.include?('Sam Smiths'), 'material contributor[Sam Smiths] missing.'
    refute material.contributors.include?('Wily Coyote'), 'material contributor[Wily Coyote] exists.'
    # fields
    refute material.fields.nil?, 'material fields is nil'
    refute_empty material.fields, 'material fields is empty'
    ['Software Engineering','MATHEMATICS'].each do |field|
      assert_includes material.fields, field, "material fields item[#{field}] is missing"
    end
    refute_includes material.fields, '', 'material fields should not include a blank entry.'
    # audiences
    refute material.target_audience.nil?, 'material target audience is nil'
    refute_empty material.target_audience, 'material target audience is empty'
    ['mbr','ecr','phd'].each do |target|
      assert_includes material.target_audience, target, "material target audience does not include #{target}"
    end
    refute_includes material.target_audience, '', 'material target audience should not include blank item.'
    # types
    refute_nil material.resource_type
    refute_empty material.resource_type
    ['presentation','other','handout'].each do |type|
      assert_includes material.resource_type, type
    end
    refute_includes material.resource_type, ''
    # other types
    refute_nil material.other_types
    assert_equal 'Technical Report', material.other_types
    # objectives
    refute_nil material.learning_objectives
    assert_equal "Various \"**undefined**\" objectives.", material.learning_objectives
    # prerequisites
    refute_nil material.prerequisites
    assert_equal "No previous skills or experience required.", material.prerequisites
    # syllabus
    refute_nil material.syllabus
    assert_equal "To be advised.", material.syllabus
    # finished
  end

  test 'validate ingestion of another material from csv file' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]

    # check materials don't exist
    title = 'Another Material'
    url = 'https://app.com/materials/material2.html'
    assert get_material(title, url).nil?

    # expect to add 2 materials
    assert_difference 'Material.count', 2 do
      freeze_time(stub_time = Time.new(2022)) do ||
        # run task - expect added[2] updated[0] rejected[1]
        Rake::Task['tess:automated_ingestion'].invoke
      end
    end

    # check material added successfully
    material = get_material title, url
    refute material.nil?, "Post-task: material from search title[#{title}] in nil."
    refute material.contact.nil?, "#{title}: contact is nil."
    assert_equal 'user@provider.portal', material.contact, "#{title}: contact should match default (content_provider)."
    refute material.doi.nil?, "#{title}: doi is nil."
    assert_equal 'https://doi.org/10.5281/zenodo.5778051', material.doi, "#{title}: doi not matched."
  end

  test 'check ingestion and updating of material from csv file' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]

    # create event
    username = 'Dale'
    user = User.find_by_username(username)
    assert !user.nil?, "Username[#{username}] not found!"

    provider_title = 'Another Portal Provider'
    provider = ContentProvider.find_by_title(provider_title)
    assert !provider.nil?, "Provider title[#{provider_title}] not found!"

    title = 'Another Material'
    url = 'https://app.com/materials/material2.html'
    description = 'default description'
    locked_fields = ['description',]

    # expect to add 1 material
    assert get_material(title, url).nil?
    assert_difference 'Material.count', 1 do
      params = { user: user, content_provider: provider, url: url, title: title, description: description,
                 keywords: ['Man', 'Woman', 'Person', 'Computer', 'Window',], contact: 'Dummy Contact',
                 licence: 'GPL-3.0', status: ['development',], locked_fields: locked_fields }
      material = Material.new(params)
      assert material.save!, 'New material not saved!'
      assert !material.nil?, 'New material not found!'
    end

    # expect to add 1 material and update 1 material
    assert_difference 'Material.count', 1 do
      freeze_time(stub_time = Time.new(2022)) do ||
        # run task - expect added[1] updated[1] rejected[1]
        Rake::Task['tess:automated_ingestion'].invoke
      end
    end

    # get event (again)
    updated = get_material title, url, provider
    refute updated.nil?, "Updated material not found!"

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
    message = 'materials processed\[3\] added\[1\] updated\[1\] rejected\[1\]'
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

  def get_material(title, url, provider = nil)
    if provider.nil?
      materials = Material.where(title: title, url: url)
    else
      materials = Material.where(title: title, url: url, content_provider: provider)
    end
    materials.nil? or materials.empty? ? nil : materials.first
  end
end