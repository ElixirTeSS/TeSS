# frozen_string_literal: true

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
      freeze_time(Time.new(2019).utc) do
        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)
      end
    end

    assert_equal 17, ingestor.materials.count
    assert_empty ingestor.events
    assert_equal 17, ingestor.stats[:materials][:added]
    assert_equal 0, ingestor.stats[:materials][:updated]
    assert_equal 0, ingestor.stats[:materials][:rejected]

    # check material added successfully
    material = get_zenodo_id(5_711_863, 'ML4AU: Trainings, trainers and building an ML community', 'Portal Provider')

    refute_nil material.description, 'material description is nil!'
    refute_nil material.keywords, 'material keywords is nil'
    assert_equal 5, material.keywords.size, 'material keywords count not matched.'
    assert_includes material.keywords, 'machine learning', 'material keyword[machine learning] missing.'
    assert_includes material.keywords, 'community of practice', 'material keyword[community of practice] missing.'
    assert_equal 'CC-BY-4.0', material.licence, 'material licence not matched'
    assert_equal 'active', material.status, 'material status not matched'
    assert_equal 1, material.authors.size, 'material authors count not matched.'
    assert_includes material.authors, 'Bonu, Tarun (orcid: 0000-0002-3910-3475)'
    assert_equal '10.5281/zenodo.5711863', material.doi, 'material.doi not matched.'

    # check material with contributors
    material = get_zenodo_id(5_091_260, 'How can software containers help your research?', 'Portal Provider')

    refute_nil material.description, 'material description is nil!'
    refute_nil material.contributors, 'material keywords is nil'
    assert_equal 6, material.contributors.size, 'material contributors count not matched!'
    assert_includes material.contributors, 'Martinez, Paula Andrea (type: ProjectLeader)',
                    'material contributors[0] missing.'
    assert_includes material.contributors, 'The ARDC Communications Team (type: Editor)',
                    'material contributors[2] missing.'
    assert_equal '10.5281/zenodo.5091260', material.doi, 'material.doi not matched.'
  end

  private

  def get_zenodo_id(id, title, provider)
    url = "https://zenodo.org/record/#{id}"
    materials = Material.where(title: title, url: url)

    refute_nil materials, "Post-task: Material title[#{title}] search error."
    assert_equal 1, materials.size, "Post-task: materials search title[#{title}] found nothing"
    material = materials.first

    refute_nil material, "Post-task: first material from search title[#{title}] in nil."
    assert_equal title, material.title, 'material title not matched!'
    assert_equal url, material.url, 'material url not matched!'
    refute_nil material.content_provider, 'material provider is nil.'
    assert_equal provider, material.content_provider.title, 'material provider not matched'
    material
  end
end
