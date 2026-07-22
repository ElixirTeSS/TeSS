require 'test_helper'

class OaiPmhIngestorTest < ActiveSupport::TestCase
  setup do
    @ingestor = Ingestors::OaiPmhIngestor.new
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    @oai_pmh_url = 'https://example.org/oai-pmh'
    @oai_pmh_id = 'example'
  end

  test 'should read empty oai pmh endpoint' do
    mock_oai_pmh([], [])

    @ingestor.read(@oai_pmh_url)

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

    mock_oai_pmh([], [record])

    @ingestor.read(@oai_pmh_url)

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

    mock_oai_pmh([], [record])

    @ingestor.read(@oai_pmh_url)

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

    mock_oai_pmh([], [material1, material2, event1, event2])

    @ingestor.read(@oai_pmh_url)

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

    mock_oai_pmh([material, material, event], [])

    @ingestor.read(@oai_pmh_url)

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

  test 'should read TeSS instance OAI-PMH endpoint and store origin URI' do
    VCR.use_cassette('ingestors/tess_oai_pmh_listrecords') do
      VCR.use_cassette('ingestors/tess_oai_pmh_identify') do
        @ingestor.read('https://oai-pmh.tesshub.space/oai-pmh')
      end
    end

    assert_equal 2, @ingestor.materials.length
    assert @ingestor.materials.all? { |m| m.origin_uri.start_with?('https://tesshub.space/materials/') }
  end

  private

  IDENTIFY = %(
<?xml-stylesheet type="text/xsl" href="/oai2xhtml.xsl"?>
<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
  <responseDate>2026-07-22T09:37:47Z</responseDate>
  <request verb="Identify">https://tesshub.space/oai-pmh</request>
  <Identify>
    <repositoryName>OAI-PMH Provider</repositoryName>
    <baseURL>https://some-oai-pmh.org/oai-pmh</baseURL>
    <protocolVersion>2.0</protocolVersion>
    <adminEmail>contact@example.com</adminEmail>
    <earliestDatestamp>2026-07-21T12:59:13Z</earliestDatestamp>
    <deletedRecord>transient</deletedRecord>
    <granularity>YYYY-MM-DDThh:mm:ssZ</granularity>
    <description>
      <oai-identifier xmlns="http://www.openarchives.org/OAI/2.0/oai-identifier" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai-identifier http://www.openarchives.org/OAI/2.0/oai-identifier.xsd">
        <scheme>oai</scheme>
        <repositoryIdentifier>some-oai-pmh</repositoryIdentifier>
        <delimiter>:</delimiter>
        <sampleIdentifier>some-oai-pmh:142</sampleIdentifier>
      </oai-identifier>
    </description>
  </Identify>
</OAI-PMH>
)

  LIST_RECORDS_WRAPPER = %(
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="/oai2xhtml.xsl"?>
<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
  <responseDate>2026-07-21T13:06:44Z</responseDate>
  <request metadataPrefix="rdf" verb="ListRecords">https://tesshub.space/oai-pmh</request>
  <ListRecords>
    %{records}
  </ListRecords>
</OAI-PMH>
)



  # ?verb=Identify
  # ?metadataPrefix=rdf&verb=ListRecords
  # ?metadataPrefix=oai_dc&verb=ListRecords
  def mock_oai_pmh(rdf_strings, dc_strings)
    WebMock.stub_request(:get, "#{@oai_pmh_url}?verb=Identify").to_return(status: 200, body: IDENTIFY)

    id = 1
    rdf_response = LIST_RECORDS_WRAPPER % { records: rdf_strings.map do |rdf|
      %(
<record>
  <header>
    <identifier>oai:#{@oai_pmh_id}:#{id += 1}</identifier>
    <datestamp>#{Time.now.utc.iso8601}</datestamp>
  </header>
  #{rdf}
</record>
      )
    end.join("\n") }
    WebMock.stub_request(:get, "#{@oai_pmh_url}?metadataPrefix=rdf&verb=ListRecords").to_return(status: 200, body: rdf_response)

    dc_response = LIST_RECORDS_WRAPPER % { records: dc_strings.map do |rdf|
      %(
<record>
  <header>
    <identifier>oai:#{@oai_pmh_id}:#{id += 1}</identifier>
    <datestamp>#{Time.now.utc.iso8601}</datestamp>
  </header>
  #{rdf}
</record>
      )
    end.join("\n") }
    WebMock.stub_request(:get, "#{@oai_pmh_url}?metadataPrefix=oai_dc&verb=ListRecords").to_return(status: 200, body: dc_response)
  end
end
