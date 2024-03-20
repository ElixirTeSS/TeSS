# frozen_string_literal: true

require 'test_helper'

class RstIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest materials from rst' do
    source = @content_provider.sources.build(
      url: 'https://researchsoftwaretraining.nl/resources/',
      method: 'rst',
      enabled: true
    )

    ingestor = Ingestors::RstIngestor.new

    # check materials don't exist
    new_title = 'Software Carpentry'
    new_url = 'https://software-carpentry.org/lessons/'
    refute Material.where(title: new_title, url: new_url).any?

    # run task
    assert_difference('Material.count', 24) do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/rst') do
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
    assert_equal 'Software Carpentry', material.description
  end
end
