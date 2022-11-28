require 'test_helper'

class ZenodoIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:portal_provider)
    mock_ingestions
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
    assert_difference('Material.count', 17) do
      freeze_time(Time.new(2019)) do
        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)
      end
    end

    assert_equal 17, ingestor.materials.count
    assert ingestor.events.empty?
    assert_equal 17, ingestor.stats[:materials][:added]
    assert_equal 0, ingestor.stats[:materials][:updated]
    assert_equal 0, ingestor.stats[:materials][:rejected]

    # check material added successfully
    material = get_zenodo_id(5_711_863, 'ML4AU: Trainings, trainers and building an ML community', 'Portal Provider')
    assert !material.description.nil?, 'material description is nil!'
    assert !material.keywords.nil?, 'material keywords is nil'
    assert_equal 5, material.keywords.size, 'material keywords count not matched.'
    assert material.keywords.include?('machine learning'), 'material keyword[machine learning] missing.'
    assert material.keywords.include?('community of practice'), 'material keyword[community of practice] missing.'
    assert_equal 'CC-BY-4.0', material.licence, 'material licence not matched'
    assert_equal 'active', material.status, 'material status not matched'
    assert_equal 1, material.authors.size, 'material authors count not matched.'
    assert material.authors.include?('Bonu, Tarun (orcid: 0000-0002-3910-3475)')
    assert_equal '10.5281/zenodo.5711863', material.doi, 'material.doi not matched.'

    # check material with contributors
    material = get_zenodo_id(5_091_260, 'How can software containers help your research?', 'Portal Provider')
    assert !material.description.nil?, 'material description is nil!'
    assert !material.contributors.nil?, 'material keywords is nil'
    assert_equal 6, material.contributors.size, 'material contributors count not matched!'
    assert material.contributors.include?('Martinez, Paula Andrea (type: ProjectLeader)'), 'material contributors[0] missing.'
    assert material.contributors.include?('The ARDC Communications Team (type: Editor)'), 'material contributors[2] missing.'
    assert_equal '10.5281/zenodo.5091260', material.doi, 'material.doi not matched.'
  end

  private

  def get_zenodo_id(id, title, provider)
    url = "https://zenodo.org/record/#{id}"
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
