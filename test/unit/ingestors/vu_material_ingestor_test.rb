require 'test_helper'

class VuMaterialIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest materials from vu' do
    source = @content_provider.sources.build(
      url: 'https://vu.nl/en/education/phd-courses',
      method: 'vu_material',
      enabled: true
    )

    ingestor = Ingestors::VuMaterialIngestor.new

    # check materials don't exist
    new_title = 'Writing and presenting'
    new_url = 'https://vu.nl/en/education/phd-courses/writing-and-presenting'
    refute Material.where(title: new_title, url: new_url).any?

    # run task
    assert_difference('Material.count', 169) do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/vu_material') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    # check event does exist
    material = Material.where(title: new_title, url: new_url).first
    assert material
    assert_equal new_title, material.title
    assert_equal new_url, material.url

    # check other fields
    assert_equal 'In this course students will be trained in two important academic skills: writing, and presenting.', material.description
  end
end
