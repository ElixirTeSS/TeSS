require 'test_helper'

class FakeClient
  def initialize(rdf_strings, dc_strings)
    @rdf_response = Minitest::Mock.new
    rdf_response = rdf_strings.map do |s|
      inner_mock = Minitest::Mock.new
      outer_mock = Minitest::Mock.new
      inner_mock.expect(:metadata, outer_mock, [])
      outer_mock.expect(:to_s, s, [])
      inner_mock
    end
    dc_response = dc_strings.map do |s|
      inner_mock = Minitest::Mock.new
      outer_mock = Minitest::Mock.new
      inner_mock.expect(:metadata, outer_mock, [])
      outer_mock.expect(:to_s, s, [])
      inner_mock
    end
    @rdf_response.expect(:full, rdf_response, [])
    @dc_response = Minitest::Mock.new
    @dc_response.expect(:full, dc_response, [])
  end

  def list_records(metadata_prefix: nil)
    if metadata_prefix == 'rdf'
      @rdf_response
    elsif metadata_prefix == 'oai_dc'
      @dc_response
    end
  end
end

class OaiPmhTest < ActiveSupport::TestCase
  setup do
    @ingestor = Ingestors::OaiPmhIngestor.new
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
  end

  test 'should read empty oai pmh endpoint' do
    OAI::Client.stub(:new, FakeClient.new([], [])) do
      @ingestor.read('https://example.org')
    end
    assert_equal [], @ingestor.materials
    assert_equal [], @ingestor.events
  end

  test 'should read dublin core material' do
    record = <<~METADATA
      <metadata>
        <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
          <dc:title>dc_title</dc:title>
          <dc:description>dc_description &lt;b&gt;bold_text&lt;/b&gt;</dc:description>
          <dc:creator>A, Alice</dc:creator>
          <dc:creator>B, Bob</dc:creator>
          <dc:rights></dc:rights>
          <dc:rights>public access</dc:rights>
          <dc:rights>https://opensource.org/licenses/MIT</dc:rights>
          <dc:date>2023-06-26</dc:date>
          <dc:date>2026-06-26</dc:date>
          <dc:identifier>https://rodare.hzdr.de/record/2513</dc:identifier>
          <dc:identifier>10.14278/rodare.2269</dc:identifier>
          <dc:subject>kA</dc:subject>
          <dc:subject>kB</dc:subject>
          <dc:subject>kC</dc:subject>
        </oai_dc:dc>
      </metadata>
    METADATA

    OAI::Client.stub(:new, FakeClient.new([], [record])) do
      @ingestor.read('https://example.org')
    end
    result = @ingestor.materials.first

    assert_equal 'dc_title', result.title
    assert_equal 'dc\\_description **bold\\_text**', result.description
    assert_equal ['A, Alice', 'B, Bob'], result.authors
    assert_equal 'https://opensource.org/licenses/MIT', result.licence
    assert_equal Date.parse('2023-06-26'), result.date_created
    assert_equal Date.parse('2026-06-26'), result.date_modified
    assert_equal 'https://doi.org/10.14278/rodare.2269', result.doi
    assert_equal 'https://rodare.hzdr.de/record/2513', result.url
    assert_equal %w[kA kB kC], result.keywords
  end

  test 'should read dublin core event' do
    record = <<~METADATA
      <metadata>
        <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
          <dc:type>http://purl.org/dc/dcmitype/Event</dc:type>
          <dc:title>dc_title</dc:title>
          <dc:description>dc_description &lt;b&gt;bold_text&lt;/b&gt;</dc:description>
          <dc:identifier>https://example.org/dc_url</dc:identifier>
          <dc:creator>A, Alice</dc:creator>
          <dc:creator>B, Bob</dc:creator>
          <dc:subject>kA</dc:subject>
          <dc:subject>kB</dc:subject>
          <dc:subject>kC</dc:subject>
          <dc:date>2026-01-01</dc:date>
          <dc:date>2026-01-02</dc:date>
        </oai_dc:dc>
      </metadata>
    METADATA

    OAI::Client.stub(:new, FakeClient.new([], [record])) do
      @ingestor.read('https://example.org')
    end
    result = @ingestor.events.first

    assert_equal 'dc_title', result.title
    assert_equal 'dc\\_description **bold\\_text**', result.description
    assert_equal 'https://example.org/dc_url', result.url
    assert_equal 'A, Alice', result.organizer
    assert_equal %w[kA kB kC], result.keywords
    assert_equal Date.parse('2026-01-01'), result.start
    assert_equal Date.parse('2026-01-02'), result.end
  end

  test 'should read multiple dublin core events and materials' do
    event1 = <<~METADATA
      <metadata>
        <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
          <dc:type>http://purl.org/dc/dcmitype/Event</dc:type>
          <dc:title>title1</dc:title>
        </oai_dc:dc>
      </metadata>
    METADATA

    event2 = <<~METADATA
      <metadata>
        <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
          <dc:type>http://purl.org/dc/dcmitype/Event</dc:type>
          <dc:title>title2</dc:title>
        </oai_dc:dc>
      </metadata>
    METADATA

    material1 = <<~METADATA
      <metadata>
        <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
          <dc:title>title3</dc:title>
        </oai_dc:dc>
      </metadata>
    METADATA

    material2 = <<~METADATA
      <metadata>
        <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
          <dc:title>title4</dc:title>
        </oai_dc:dc>
      </metadata>
    METADATA

    OAI::Client.stub(:new, FakeClient.new([], [material1, material2, event1, event2])) do
      @ingestor.read('https://example.org')
    end

    assert_equal %w[title1 title2], @ingestor.events.map(&:title)
    assert_equal %w[title3 title4], @ingestor.materials.map(&:title)
  end

  test 'should read bioschemas' do
    material = <<~METADATA
      <metadata><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:sdo="http://schema.org/" xmlns:dc="http://purl.org/dc/terms/">
        <sdo:LearningResource rdf:about="https://pan-training.eu/materials/python-laser-image-visualization">
          <dc:conformsTo>
            <sdo:CreativeWork rdf:about="https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE">
            </sdo:CreativeWork>
          </dc:conformsTo>
          <sdo:name>bioschemas title</sdo:name>
          <sdo:url rdf:resource="https://example.org/bioschemas/material"/>
          <sdo:license rdf:resource="https://opensource.org/licenses/MIT"/>
        </sdo:LearningResource>
      </rdf:RDF></metadata>
    METADATA

    event = <<~METADATA
      <metadata><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:sdo="http://schema.org/" xmlns:dc="http://purl.org/dc/terms/">
        <sdo:Event rdf:about="https://pan-training.eu/materials/python-laser-image-visualization">
          <sdo:name>bioschemas title2</sdo:name>
          <sdo:url rdf:resource="https://example.org/bioschemas/event"/>
        </sdo:Event>
      </rdf:RDF></metadata>
    METADATA

    OAI::Client.stub(:new, FakeClient.new([material, material, event], [])) do
      @ingestor.read('https://example.org')
    end

    assert_equal 1, @ingestor.materials.length
    result = @ingestor.materials.first
    assert_equal 'bioschemas title', result.title
    assert_equal 'https://example.org/bioschemas/material', result.url
    assert_equal 'https://opensource.org/licenses/MIT', result.licence

    assert_equal 1, @ingestor.events.length
    result = @ingestor.events.first
    assert_equal 'bioschemas title2', result.title
    assert_equal 'https://example.org/bioschemas/event', result.url
  end
end
