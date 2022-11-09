require 'test_helper'

class BioschemasIngestorTest < ActiveSupport::TestCase
  setup do
    @ingestor = Ingestors::BioschemasIngestor.new
    @user = users(:regular_user)
    @content_provider = content_providers(:portal_provider)
  end

  test 'ingest events from a bioschemas courseinstance json endpoint' do
    mock_bioschemas('https://website.org/courseinstances.json', 'nbis-course-instances.json')
    @ingestor.read('https://website.org/courseinstances.json')
    assert_equal 23, @ingestor.events.count
    assert_equal 0, @ingestor.materials.count
    sample = @ingestor.events.detect { |e| e.title == 'Neural Networks and Deep Learning' }

    assert_difference('Event.count', 23) do
      @ingestor.write(@user, @content_provider)
    end

    assert sample.persisted?
    assert_equal "https://uppsala.instructure.com/courses/75565", sample.url
    assert_includes sample.description, "This course will give an introduction to the concept of Neural Networks"
    assert_equal "2023-03-20T00:00:00Z", sample.start.utc.iso8601
    assert_equal "2023-03-24T00:00:00Z", sample.end.utc.iso8601
    assert_equal "SciLifeLab Uppsala - Navet, Husargatan 3", sample.venue
    assert_equal "Uppsala", sample.city
    assert_equal "Sweden", sample.country
    assert_equal @content_provider, sample.content_provider
    assert_equal @user, sample.user
    assert_equal 25, sample.capacity
  end

  test 'ingest bioschemas from a sitemap' do
    mock_bioschemas('https://training.galaxyproject.org/sitemap.xml', 'gtn/sitemap.xml')
    mock_bioschemas('https://training.galaxyproject.org/training-material/topics/introduction/slides/introduction.html', 'gtn/slides-introduction.html')
    mock_bioschemas('https://training.galaxyproject.org/training-material/topics/introduction/tutorials/galaxy-intro-101/tutorial.html', 'gtn/galaxy-intro-101.html')
    mock_bioschemas('https://training.galaxyproject.org/training-material/topics/introduction/tutorials/galaxy-intro-strands/tutorial.html', 'gtn/galaxy-intro-strands.html')
    mock_bioschemas('https://training.galaxyproject.org/page-with-no-bioschemas', 'gtn/faq.html')
    mock_bioschemas('https://training.galaxyproject.org/page-with-no-bioschemas-2', 'gtn/faq.html')
    WebMock.stub_request(:get, 'https://training.galaxyproject.org/404').to_return(status: 404, headers: {})

    @ingestor.read('https://training.galaxyproject.org/sitemap.xml')
    assert_equal 0, @ingestor.events.count
    assert_equal 3, @ingestor.materials.count
    sample = @ingestor.materials.detect { |e| e.title == "Introduction to 'Introduction to Galaxy Analyses'" }

    assert_difference('Material.count', 3) do
      @ingestor.write(@user, @content_provider)
    end

    assert sample.persisted?
    assert_equal "https://training.galaxyproject.org/training-material/topics/introduction/slides/introduction.html",  sample.url
    assert_equal "Slides for Introduction to Galaxy Analyses", sample.description
    assert_equal ["Students"], sample.target_audience
    assert_equal ["Andrea Bagnacani",
                  "Anne Fouilloux",
                  "Anne Pajon",
                  "Bérénice Batut",
                  "Christopher Barnett",
                  "Dave Clements",
                  "Helena Rasche",
                  "Michele Maroni",
                  "Nadia Goué",
                  "Nicola Soranzo",
                  "Olha Nahorna",
                  "Saskia Hiltemann"], sample.authors
    assert_equal ["Andrea Bagnacani",
                  "Anne Fouilloux",
                  "Anne Pajon",
                  "Bérénice Batut",
                  "Christopher Barnett",
                  "Dave Clements",
                  "Helena Rasche",
                  "Michele Maroni",
                  "Nadia Goué",
                  "Nicola Soranzo",
                  "Olha Nahorna",
                  "Saskia Hiltemann"], sample.contributors
    assert_equal "CC-BY-4.0", sample.licence
    assert_equal ["slides"], sample.resource_type
    assert_equal @content_provider, sample.content_provider
    assert_equal @user, sample.user
  end

  private

  def mock_bioschemas(url, filename)
    file = Rails.root.join('test', 'fixtures', 'files', 'ingestion', filename)
    WebMock.stub_request(:get, url).to_return(status: 200, headers: {}, body: file.read )
  end
end
