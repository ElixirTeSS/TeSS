require 'test_helper'

class HanIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest materials from han' do
    source = @content_provider.sources.build(
      url: 'https://www.han.nl/studeren/scholing-voor-werkenden/laboratorium/',
      method: 'han',
      enabled: true
    )

    ingestor = Ingestors::Taxila::HanIngestor.new

    # check materials don't exist
    new_title = 'Synthetiseren en Karakteriseren van Moleculen'
    new_url = 'https://www.han.nl/opleidingen/module/synthetiseren-karakteriseren-moleculen/'
    refute Material.where(title: new_title, url: new_url).any?

    # run task
    assert_difference('Material.count', 27) do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/han') do
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
    # assert_equal 'Software Carpentry lessons introduce basic lab skills for research computing. They cover three core topics: the Unix shell, version control with Git, and a programming language (Python or R). ',
    #              material.description
  end
end
