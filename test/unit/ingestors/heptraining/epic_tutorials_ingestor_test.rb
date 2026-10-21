# frozen_string_literal: true

require 'test_helper'

class EpicTutorialsIngestorTest < ActiveSupport::TestCase
  setup do
    @ingestor = Ingestors::Heptraining::EpicTutorialsIngestor.new
    @user = users(:regular_user)
    @content_provider = content_providers(:portal_provider)

    webmock('https://raw.githubusercontent.com/eic/tutorials/main/tutorials.md', 'heptraining/epictutorials/epic-page.md')
    # Github
    webmock('https://github.com/hsf-training/cpluspluscourse', 'github/mock.html')
    webmock('https://api.github.com/repos/hsf-training/cpluspluscourse', 'github/api-github-com.json')
    webmock('https://api.github.com/repos/hsf-training/cpluspluscourse/contributors', 'github/contributors.json')
    webmock('https://api.github.com/repos/hsf-training/cpluspluscourse/contents/README.md', 'github/readme.json')
    webmock('https://api.github.com/repos/hsf-training/cpluspluscourse/releases', 'github/releases.json')

    # Indico
    webmock('https://indico.bnl.gov/event/27123', 'indico/indico.html')
    webmock('https://indico.bnl.gov/event/27123/event.ics', 'indico/event.ics')
  end

  test 'config' do
    config = Ingestors::Heptraining::EpicTutorialsIngestor.config

    assert_equal 'epic_tutorials', config[:key]
    assert_equal 'ePIC Tutorials', config[:title]
    assert_equal :materials, config[:category]
    assert_equal 'TeSS ePIC Tutorials ingestor', config[:user_agent]
  end

  test 'github_url?' do
    assert @ingestor.send(:github_url?, 'https://github.com/eic/tutorial-setting-up-environment')
    assert @ingestor.send(:github_url?, 'https://eic.github.io/tutorial-setting-up-environment')
    refute @ingestor.send(:github_url?, 'https://indico.bnl.gov/event/27123/')
    refute @ingestor.send(:github_url?, 'not_a_valid_url')
  end

  test 'indico_url?' do
    assert @ingestor.send(:indico_url?, 'https://indico.bnl.gov/event/27123/')
    assert @ingestor.send(:indico_url?, 'https://indico.cern.ch/event/12345/')
    refute @ingestor.send(:indico_url?, 'https://eic.github.io/scavenger-hunt')
  end

  test 'should read epic tutorials source and attach external resources' do
    # Stub delegation to sub-ingestors
    @ingestor.read('https://raw.githubusercontent.com/eic/tutorials/main/tutorials.md')
    @ingestor.write(@user, @content_provider)

    assert_equal 2, @ingestor.materials.count
    assert_equal 1, @ingestor.events.count

    evt = @ingestor.events.detect { |e| e.title == '14th HEP C++ Course and Hands-on Training - The Essentials' }
    assert evt.persisted?
    assert_equal evt.url, 'https://indico.cern.ch/event/1617123/'
    assert_equal evt.description, 'speakers and Zoom here, however it is not hybrid'
    assert_equal 1, evt.external_resources.size
    extres0 = evt.external_resources[0]
    assert_equal 'Youtube', extres0.title
    assert_equal 'https://youtu.be/goONxXudL-s', extres0.url


    mat = @ingestor.materials.detect { |e| e.title == 'Cpluspluscourse' }
    assert mat.persisted?
    assert_equal mat.description, 'C++ Course Taught at CERN'
    assert_equal 2, mat.external_resources.size
    extres1 = mat.external_resources[0]
    assert_equal 'Youtube 1', extres1.title
    assert_equal 'https://www.youtube.com/watch?v=Y0Mg24XLomY', extres1.url
    extres2 = mat.external_resources[1]
    assert_equal 'Youtube 2', extres2.title
    assert_equal 'https://www.youtube.com/watch?v=5HmzFnYW4W4', extres2.url
  end

  test 'fetch_from_other_ingestor delegates to GithubIngestor and IndicoIngestor' do
    gh_url = 'https://eic.github.io/tutorial-setting-up-environment'
    indico_url = 'https://indico.bnl.gov/event/27123/'
    unknown_url = 'https://example.com/tutorial'

    mock_gh_material = Material.new(title: 'GH Mat')
    mock_indico_event = Event.new(title: 'Indico Evt')

    # Test GitHub delegation
    gh_mock = Minitest::Mock.new
    gh_mock.expect(:read, true, [gh_url])
    gh_mock.expect(:materials, [mock_gh_material])
    gh_mock.expect(:events, [])

    Ingestors::GithubIngestor.stub(:new, gh_mock) do
      gh_res = @ingestor.send(:fetch_from_other_ingestor, gh_url)
      assert_equal [mock_gh_material], gh_res[0]
      assert_equal [], gh_res[1]
    end
    gh_mock.verify

    # Test Indico delegation
    indico_mock = Minitest::Mock.new
    indico_mock.expect(:read, true, [indico_url])
    indico_mock.expect(:materials, [])
    indico_mock.expect(:events, [mock_indico_event])

    Ingestors::IndicoIngestor.stub(:new, indico_mock) do
      indico_res = @ingestor.send(:fetch_from_other_ingestor, indico_url)
      assert_equal [], indico_res[0]
      assert_equal [mock_indico_event], indico_res[1]
    end
    indico_mock.verify

    # Test unknown URL
    unknown_res = @ingestor.send(:fetch_from_other_ingestor, unknown_url)
    assert_equal [[], []], unknown_res
  end

  test 'std errors when exception is raised during read' do
    @ingestor.stub(:open_url, ->(*) { raise StandardError, 'connection error' }) do
      mock_logger = Minitest::Mock.new
      mock_logger.expect(:error, nil, ['StandardError: read() failed, connection error'])

      Rails.stub(:logger, mock_logger) do
        @ingestor.read('https://raw.githubusercontent.com/eic/tutorials/main/tutorials.md')
      end

      mock_logger.verify
    end
  end

  private

  def webmock(url, filename)
    file = Rails.root.join('test', 'fixtures', 'files', 'ingestion', filename)
    WebMock.stub_request(:get, url).to_return(status: 200, headers: {}, body: file.read)
  end
end