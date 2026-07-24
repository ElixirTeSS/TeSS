# frozen_string_literal: true

require 'test_helper'

class CdsVideosIngestorTest < ActiveSupport::TestCase
  setup do
    @ingestor = Ingestors::CdsVideosIngestor.new
    @user = users(:regular_user)
    @content_provider = content_providers(:portal_provider)

    # API record
    webmock('https://videos.cern.ch/api/record/3023615', 'cdsvideos/cds.ingestor.json')
  end

  test 'returns expected ingestor config' do
    config = Ingestors::CdsVideosIngestor.config
    assert_equal 'cds videos', config[:key]
    assert_equal :materials, config[:category]
  end

  test 'to_api formats record URL correctly' do
    url = 'https://videos.cern.ch/record/3023615'
    expected = 'https://videos.cern.ch/api/record/3023615'
    assert_equal expected, @ingestor.send(:to_api, url)
  end

  test 'to_api formats search URL correctly' do
    url = 'https://videos.cern.ch/search?q=test'
    expected = 'https://videos.cern.ch/api/records?q=test'
    assert_equal expected, @ingestor.send(:to_api, url)
  end

  test 'update_url_field_value updates query parameters' do
    url = 'https://videos.cern.ch/api/records?q=test&page=2'
    updated = @ingestor.send(:update_url_field_value, url, 'page', 1)
    assert_equal 'https://videos.cern.ch/api/records?q=test&page=1', updated
  end

  test 'should read cds source and map properties correctly' do
    @ingestor.read('https://videos.cern.ch/record/3023615')

    assert_equal 1, @ingestor.materials.count
    sample = @ingestor.materials.first

    assert_equal 'Hi For Accelerator Driven Systems', sample.title
    assert_equal 'https://videos.cern.ch/record/3023615', sample.url
    assert_equal 'other-at', sample.licence
    assert_equal 'Active', sample.status
    assert_equal 'Cas.News@Cern.Ch', sample.contact
    assert_equal 'LECTURES-VIDEO-2026-2754-001', sample.version
    assert_equal '2025-06-26', sample.date_created
    assert_equal '2026-03-18', sample.date_published
    assert_equal ['Noemi Caraban'], sample.authors
    assert_equal ['Dorda Ulrich'], sample.contributors
    assert_equal 'Video – Lectures', sample.resource_type
    
    expected_keywords = 'Ulrich Dorda, Beam cooling, high-intensity beams, beam quality, hadron beams, cooling techniques, beam emittance, stochastic cooling, electron cooling, ionization cooling'
    assert_equal expected_keywords, sample.keywords

    assert_match 'After presenting the motivation for an Accelerator Driven System', sample.description
    assert_match 'Video duration: 00:48:34', sample.description
    assert_match 'CAS - CERN Accelerator School', sample.description
    assert_match 'Is part of: https://indico.cern.ch/event/1466612/contributions/6449173/ (URL)', sample.description
    assert_match 'Copyright: [CERN](https://copyright.web.cern.ch/) (2025)', sample.description
  end

  test 'std errors when exception is raised' do
    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil, [/StandardError: read\(\) failed, test failure/])

    Rails.stub(:logger, mock_logger) do
      @ingestor.stub(:open_url, ->(*) { raise StandardError, 'test failure' }) do
        @ingestor.read('https://videos.cern.ch/record/3023615')
      end
    end

    mock_logger.verify
  end

test 'should read search source with pagination across multiple pages' do
    search_url = 'https://videos.cern.ch/search?q=physics'
    page1_api_url = 'https://videos.cern.ch/api/records?q=physics&page=1&size=100'
    page2_api_url = 'https://videos.cern.ch/api/records?q=physics&page=2&size=100'

    record_fixture = JSON.parse(File.read(Rails.root.join('test/fixtures/files/ingestion/cdsvideos/cds.ingestor.json')))

    page1_payload = {
      'hits' => { 'hits' => [record_fixture] },
      'links' => { 'next' => page2_api_url }
    }.to_json

    page2_payload = {
      'hits' => { 'hits' => [record_fixture] },
      'links' => {}
    }.to_json

    WebMock.stub_request(:get, page1_api_url).to_return(status: 200, body: page1_payload)
    WebMock.stub_request(:get, page2_api_url).to_return(status: 200, body: page2_payload)

    @ingestor.read(search_url)

    assert_equal 2, @ingestor.materials.count
    assert_equal 'Hi For Accelerator Driven Systems', @ingestor.materials.first.title
  end

  test 'should handle search source with empty hits gracefully' do
    search_url = 'https://videos.cern.ch/search?q=nonexistent'
    api_url = 'https://videos.cern.ch/api/records?q=nonexistent&page=1&size=100'

    empty_payload = { 'hits' => { 'hits' => [] } }.to_json
    WebMock.stub_request(:get, api_url).to_return(status: 200, body: empty_payload)

    @ingestor.read(search_url)

    assert_empty @ingestor.materials
  end

  private

  def webmock(url, filename)
    file = Rails.root.join('test', 'fixtures', 'files', 'ingestion', filename)
    WebMock.stub_request(:get, url).to_return(status: 200, headers: {}, body: file.read)
  end
end