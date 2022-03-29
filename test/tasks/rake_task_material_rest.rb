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

    # check materials don't exist
    materials = Material.where(title: 'My First Material', url: 'https://app.com/materials/material1.html')
    assert !materials.nil?, "Pre-task: Materials search error."
    assert_equal 0, materials.size, "Pre-task: Materials search title[My First Material] found something"

    # run task
    assert_difference 'Material.count', 28 do
      freeze_time(stub_time = Time.new(2019)) do ||
        Rake::Task['tess:automated_ingestion'].invoke
      end
    end

    # check material added successfully
    material = get_zenodo_id(5711863, 'ML4AU: Trainings, trainers and building an ML community', 'Portal Provider')
    assert !material.description.nil?, 'material description is nil!'
    assert !material.keywords.nil?, 'material keywords is nil'
    assert_equal 5, material.keywords.size, 'material keywords count not matched.'
    assert material.keywords.include?('machine learning'), 'material keyword[machine learning] missing.'
    assert material.keywords.include?('community of practice'), 'material keyword[community of practice] missing.'
    assert_equal material.content_provider.contact, material.contact, 'material contact not matched'
    assert_equal 'CC-BY-4.0', material.licence, 'material licence not matched'
    assert_equal 'active', material.status, 'material status not matched'
    assert_equal 1, material.authors.size, 'material authors count not matched.'
    assert material.authors.include?('Bonu, Tarun (orcid: 0000-0002-3910-3475)')
    assert_equal '10.5281/zenodo.5711863', material.doi, 'material.doi not matched.'

    # check material with contributors
    material = get_zenodo_id(5091260, 'How can software containers help your research?', 'Portal Provider')
    assert !material.description.nil?, 'material description is nil!'
    assert !material.contributors.nil?, 'material keywords is nil'
    assert_equal 6, material.contributors.size, 'material contributors count not matched!'
    assert material.contributors.include?('Martinez, Paula Andrea (type: ProjectLeader)'), 'material contributors[0] missing.'
    assert material.contributors.include?('The ARDC Communications Team (type: Editor)'), 'material contributors[2] missing.'
    assert_equal '10.5281/zenodo.5091260', material.doi, 'material.doi not matched.'

    # check material with updated keywords
    material = get_zenodo_id(5546631, 'ORCID in Australia', 'Portal Provider')
    assert !material.description.nil?, 'material description is nil'
    assert_equal 'The description has also been updated!', material.description, 'material description not matched!'
    assert !material.keywords.nil?, 'material keywords is nil'
    assert_equal 5, material.keywords.size, 'material keywords count not matched.'
    assert material.keywords.include?('Test'), 'material keyword[Test] missing.'
    assert_equal '10.5281/zenodo.5546631', material.doi, 'material.doi not matched.'

    # check material from another provider
    material = get_zenodo_id(5068997, 'WEBINAR: Getting started with command line bioinformatics',
                             'Another Portal Provider')
    assert !material.description.nil?, 'material description is nil'
    assert !material.keywords.nil?, 'material keywords is nil'
    assert_equal 5, material.keywords.size, 'material keywords count not matched.'
    assert material.keywords.include?('Bioinformatics'), 'material keyword[machine learning] missing.'
    assert_equal material.content_provider.contact, material.contact, 'material contact not matched'
    assert_equal 'CC-BY-4.0', material.licence, 'material licence not matched'
    assert_equal 'active', material.status, 'material status not matched'
    assert_equal 1, material.authors.size, 'material authors count not matched.'
    assert material.authors.include?('Brandies, Parice (orcid: 0000-0003-1702-2938)'), 'material.authors missing entry.'
    assert_equal 1, material.contributors.size, 'material authors count not matched.'
    assert material.contributors.include?('Hogg, Carolyn (type: Supervisor)'), 'material.contributors missing entry.'
    assert_equal '10.5281/zenodo.5068997', material.doi, 'material.doi not matched.'

    # check logfile messages
    message = 'Scraper.run: finish'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Sources processed = 10'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'materials processed\[17\] added\[17\] updated\[0\] rejected\[0\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'materials processed\[10\] added\[10\] updated\[0\] rejected\[0\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'materials processed\[3\] added\[1\] updated\[1\] rejected\[1\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message

    # check logfile messages
    message = 'Source URL\[https://zenodo.org/api/records/\?communities=ardc\] resources read\[17\] and written\[17\].'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Source URL\[https://zenodo.org/api/records/\?communities=australianbiocommons-training\] resources read\[10\] and written\[10\].'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Source URL\[https://zenodo.org/api/records/\?communities=ardc-again\] resources read\[3\] and written\[2\].'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end

  private

  def get_zenodo_id (id, title, provider)
    url = "https://zenodo.org/record/#{id}"
    materials = Material.where(title: title, url: url)
    assert !materials.nil?, "Post-task: Material title[#{title}] search error."
    assert_equal 1, materials.size, "Post-task: materials search title[#{title}] found nothing"
    material = materials.first
    assert !material.nil?, "Post-task: first material from search title[#{title}] in nil."
    assert_equal title, material.title, "material title not matched!"
    assert_equal url, material.url, "material url not matched!"
    assert !material.content_provider.nil?, "material provider is nil."
    assert_equal provider, material.content_provider.title, 'material provider not matched'
    return material
  end

end