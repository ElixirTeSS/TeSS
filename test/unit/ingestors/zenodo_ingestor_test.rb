require 'test_helper'

class ZenodoIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest materials from zenodo' do
    source = @content_provider.sources.build(
      url: 'https://zenodo.org/api/records/?communities=ardc',
      method: 'zenodo',
      enabled: true
    )

    ingestor = Ingestors::ZenodoIngestor.new

    # check materials don't exist
    refute Material.where(title: 'My First Material', url: 'https://app.com/materials/material1.html').any?

    # run task
    assert_difference('Material.count', 50) do
      freeze_time(2019) do
        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)
      end
    end

    assert_equal 50, ingestor.materials.count
    assert ingestor.events.empty?
    assert_equal 50, ingestor.stats[:materials][:added]
    assert_equal 0, ingestor.stats[:materials][:updated]
    assert_equal 0, ingestor.stats[:materials][:rejected]

    # check material added successfully
    material = get_zenodo_id(10656276, 'Australian national Persistent Identifier (PID) strategy 2024', 'Portal Provider')
    assert !material.description.nil?, 'material description is nil!'
    assert !material.keywords.nil?, 'material keywords is nil'
    assert_equal 3, material.keywords.size, 'material keywords count not matched.'
    assert material.keywords.include?('Persistent Identifier'), 'material keyword[Persistent Identifier] missing.'
    assert material.keywords.include?('PID'), 'material keyword[PID] missing.'
    assert_equal 'CC-BY-4.0', material.licence, 'material licence not matched'
    assert_equal 'active', material.status, 'material status not matched'
    assert_equal 1, material.authors.size, 'material authors count not matched.'
    assert material.authors.include?('Australian Research Data Commons')
    assert_equal '10.5281/zenodo.10656276', material.doi, 'material.doi not matched.'

    # check material with contributors
    material = get_zenodo_id(10525947, 'HASS and Indigenous Research Data Commons co-design framework', 'Portal Provider')
    assert !material.description.nil?, 'material description is nil!'
    assert !material.contributors.nil?, 'material keywords is nil'
    assert_equal 3, material.contributors.size, 'material contributors count not matched!'
    assert material.contributors.include?('Burton, Nichola (type: Producer)'), 'material contributors[0] missing.'
    assert material.contributors.include?('Fewster, Jennifer (type: ProjectLeader)'), 'material contributors[2] missing.'
    assert_equal '10.5281/zenodo.10525947', material.doi, 'material.doi not matched.'

    # check material from page 2
    material = get_zenodo_id(10052012, 'Privacy focused health data storage and access control through personal online datastores', 'Portal Provider')
    assert material.authors.include?('Vidanage, Anushka (orcid: 0000-0002-5386-5871)'), 'material contributors[0] missing.'
  end

  private

  def get_zenodo_id(id, title, provider)
    url = "https://zenodo.org/records/#{id}"
    materials = Material.where(title: title, url: url)
    assert !materials.nil?, "Post-task: Material title[#{title}] search error."
    assert_equal 1, materials.size, "Post-task: materials search title[#{title}] found nothing"
    material = materials.first
    assert !material.nil?, "Post-task: first material from search title[#{title}] in nil."
    assert_equal title, material.title, 'material title not matched!'
    assert_equal url, material.url, 'material url not matched!'
    assert !material.content_provider.nil?, 'material provider is nil.'
    assert_equal provider, material.content_provider.title, 'material provider not matched'
    material
  end
end
