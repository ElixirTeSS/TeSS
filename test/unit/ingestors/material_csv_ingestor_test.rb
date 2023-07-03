require 'test_helper'

class MaterialCsvIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_nominatim
  end

  def run
    with_dresa_dictionaries do
      super
    end
  end

  test 'can ingest materials from CSV file' do
    # check test material doesn't exist
    assert_nil get_material('My First Material', 'https://app.com/materials/material1.html')
    assert_nil get_material('Another Material', 'https://app.com/materials/material2.html')

    source = @content_provider.sources.build(
      url: 'https://app.com/materials.csv',
      method: 'material_csv',
      enabled: true
    )

    ingestor = Ingestors::MaterialCsvIngestor.new

    assert_difference('Material.count', 2) do
      freeze_time(2022) do
        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)
      end
    end

    assert_equal 3, ingestor.materials.count
    assert ingestor.events.empty?
    assert_equal 2, ingestor.stats[:materials][:added]
    assert_equal 0, ingestor.stats[:materials][:updated]
    assert_equal 1, ingestor.stats[:materials][:rejected]

    material = ingestor.materials.detect { |e| e.title == 'The Final Draft' }
    assert material
    assert material.errors.added?(:other_types, :blank)

    # check material added successfully with no errors
    title = 'My First Material'
    url = 'https://app.com/materials/material1.html'
    material = get_material title, url
    refute material.nil?, "material title[#{title}] not found."
    refute material.errors.nil?
    assert material.errors.empty?, "material title[#{title}] has errors"

    # check required attributes
    assert_equal title, material.title, 'material title not matched!'
    assert_equal url, material.url, 'material url not matched!'
    assert !material.content_provider.nil?, 'material provider is nil.'
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
    assert_equal Date.new(2021, 3, 14), material.date_published, 'material date_published not matched.'
    # modified
    refute material.date_modified.nil?, 'material date_modified is nil'
    assert_equal Date.new(2021, 9, 21), material.date_modified, 'material date_modified not matched.'
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
    ['Software Engineering', 'MATHEMATICS'].each do |field|
      assert_includes material.fields, field, "material fields item[#{field}] is missing"
    end
    refute_includes material.fields, '', 'material fields should not include a blank entry.'
    # audiences
    refute material.target_audience.nil?, 'material target audience is nil'
    refute_empty material.target_audience, 'material target audience is empty'
    %w[mbr ecr phd].each do |target|
      assert_includes material.target_audience, target, "material target audience does not include #{target}"
    end
    refute_includes material.target_audience, '', 'material target audience should not include blank item.'
    # types
    refute_nil material.resource_type
    refute_empty material.resource_type
    %w[presentation other handout].each do |type|
      assert_includes material.resource_type, type
    end
    refute_includes material.resource_type, ''
    # other types
    refute_nil material.other_types
    assert_equal 'Technical Report', material.other_types
    # objectives
    refute_nil material.learning_objectives
    assert_equal 'Various "**undefined**" objectives.', material.learning_objectives
    # prerequisites
    refute_nil material.prerequisites
    assert_equal 'No previous skills or experience required.', material.prerequisites
    # syllabus
    refute_nil material.syllabus
    assert_equal 'To be advised.', material.syllabus

    # check other material added successfully
    title = 'Another Material'
    url = 'https://app.com/materials/material2.html'
    material = get_material title, url
    refute material.nil?, "Post-task: material from search title[#{title}] in nil."
    # refute material.contact.nil?, "#{title}: contact is nil."
    # assert_equal 'user@provider.portal', material.contact, "#{title}: contact should match default (content_provider)."
    refute material.doi.nil?, "#{title}: doi is nil."
    assert_equal 'https://doi.org/10.5281/zenodo.5778051', material.doi, "#{title}: doi not matched."
  end

  test 'check ingestion and updating of material from csv file' do
    source = @content_provider.sources.build(
      url: 'https://app.com/materials.csv',
      method: 'material_csv',
      enabled: true
    )

    ingestor = Ingestors::MaterialCsvIngestor.new

    title = 'Another Material'
    url = 'https://app.com/materials/material2.html'
    description = 'default description'
    locked_fields = ['description']

    # expect to add 1 material
    assert get_material(title, url).nil?
    assert_difference 'Material.count', 1 do
      params = { user: @user, content_provider: @content_provider, url: url, title: title, description: description,
                 keywords: %w[Man Woman Person Computer Window], contact: 'Dummy Contact',
                 licence: 'GPL-3.0', status: ['development'], locked_fields: locked_fields }
      material = Material.new(params)
      material.save!
    end

    # expect to add 1 material and update 1 material
    assert_difference 'Material.count', 1 do
      freeze_time(2022) do
        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)
        assert_equal 3, ingestor.materials.count
        assert ingestor.events.empty?
        assert_equal 1, ingestor.stats[:materials][:added]
        assert_equal 1, ingestor.stats[:materials][:updated]
        assert_equal 1, ingestor.stats[:materials][:rejected]
      end
    end

    # get event (again)
    updated = get_material title, url, @content_provider
    refute updated.nil?, 'Updated material not found!'

    # check fields of updated material
    assert_equal url, updated.url, 'Updated URL not matched!'
    assert_equal title, updated.title, 'Updated title not matched!'
    assert_equal @content_provider, updated.content_provider, 'Updated provider not matched!'
    assert updated.scraper_record, 'Updated not a scraper record!'
    assert !updated.last_scraped.nil?, 'Updated last scraped is nil!'

    # assert_equal 'user@provider.portal', updated.contact, "Updated contact not matched!"
    assert_equal 'archived', updated.status, 'Updated status not matched!'
    assert_equal 'CC-BY-4.0', updated.licence, 'Updated licence not matched!'
    assert_equal 2, updated.keywords.size, 'Updated keywords count not matched!'
    assert updated.keywords.include?('book'), 'Updated keywords missing value!'
    assert_equal 2, updated.authors.size, "Updated authors count not matched! ... #{updated.authors.inspect}"
    assert updated.authors.include?('Steven Smith'), 'Updated authors[Steven Smith] missing!'
    assert updated.authors.include?('Sam Harpic'), 'Updated authors[Sam Harpic] missing!'
    assert_equal 0, updated.contributors.size, 'Updated contributors count not matched!'

    # check locked fields not updated
    assert_equal 1, updated.locked_fields.size, 'Updated locked_fields count not matched!'
    assert updated.field_locked?(:description), 'Updated field (:description) not locked!'
    assert_equal description, updated.description, 'Updated description has changed!'
  end

  private

  def get_material(title, url, provider = nil)
    if provider.nil?
      Material.where(title: title, url: url)
    else
      Material.where(title: title, url: url, content_provider: provider)
    end.first
  end
end
