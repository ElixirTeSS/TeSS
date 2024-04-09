require 'test_helper'

class BioschemasTest < ActionDispatch::IntegrationTest
  unless JSON::LD::Context::PRELOADED['http://schema.org/']
    puts 'Pre-loading schema.org context...'
    ctx = JSON::LD::Context.new.parse(File.join(File.dirname(__FILE__), '..', 'schemaorgcontext.jsonld'))

    JSON::LD::Context.add_preloaded('http://schema.org/', ctx)
  end

  test 'Event bioschemas on show page for non-course event' do
    event = events(:training_event)
    url = event_url(event.id)

    get url

    reader = RDF::Reader.for(:rdfa).new(response.body, base_uri: url, logger: false)
    graph = RDF::Graph.new
    graph.insert_statements(reader)

    results = graph.query([:subject, RDF.type, RDF::Vocab::SCHEMA.Event])
    event_uri = results.first.subject
    assert_equal 1, results.count
    assert_equal url, event_uri

    props = {}
    graph.query([event_uri, :p, :o]).each do |result|
      key = result.predicate.to_s.split('/').last
      props[key] ||= []
      props[key] << result.object.to_s
    end
    assert_equal ['calendar event'], props['name']
    assert_equal ['an event to test calendar exports'], props['alternateName']
    assert_equal ['http://microsoft.com'], props['url']
    assert_equal ['Keyword'], props['keywords']
    assert_equal ['2021-09-20 23:15:00 UTC'], props['startDate']
    assert_equal ['2021-09-21 01:00:00 UTC'], props['endDate']

    # Address
    q = RDF::Query.new do
      pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.location, :place)
      pattern RDF::Query::Pattern.new(:place, RDF::Vocab::SCHEMA.address, :address)
      pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.streetAddress, :street_address, optional: true)
      pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.addressLocality, :locality, optional: true)
      pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.addressRegion, :region, optional: true)
      pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.addressCountry, :country, optional: true)
      pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.postalCode, :postcode, optional: true)
      pattern RDF::Query::Pattern.new(:place, RDF::Vocab::SCHEMA.latitude, :latitude, optional: true)
      pattern RDF::Query::Pattern.new(:place, RDF::Vocab::SCHEMA.longitude, :longitude, optional: true)
    end
    results = graph.query(q)
    assert_equal 1, results.count
    assert_equal '100, Lygon Street', results.first.street_address
    assert_equal 'Carlton', results.first.locality
    assert_equal 'Australia', results.first.country
    assert_equal '3010', results.first.postcode
    assert_equal '-37.804755', results.first.latitude
    assert_equal '144.966274', results.first.longitude

    # Sponsors
    q = RDF::Query.new do
      pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.funder, :funder_info)
      pattern RDF::Query::Pattern.new(:funder_info, RDF::Vocab::SCHEMA.name, :funder)
    end
    results = graph.query(q)
    assert_equal 1, results.count
    assert_equal 'FundingCorp', results.first.funder

    # Organizer
    q = RDF::Query.new do
      pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.organizer, :organizer_info)
      pattern RDF::Query::Pattern.new(:organizer_info, RDF::Vocab::SCHEMA.name, :organizer)
    end
    results = graph.query(q)
    assert_equal 1, results.count
    assert_equal 'EventsCo', results.first.organizer
  end

  test 'Course/CourseInstance & Event bioschemas on show page for course event' do
    event = events(:course_event)
    url = event_url(event.id)

    get url

    reader = RDF::Reader.for(:rdfa).new(response.body, base_uri: url, logger: false)
    graph = RDF::Graph.new
    graph.insert_statements(reader)

    results = graph.query([:subject, RDF.type, RDF::Vocab::SCHEMA.Course])
    course_uri = results.first.subject
    assert_equal 1, results.count
    assert_equal url, course_uri

    results = graph.query([course_uri, RDF::Vocab::SCHEMA.hasCourseInstance, :course_instance])
    assert_equal 1, results.count

    results = graph.query([results.first.object, RDF.type, RDF::Vocab::SCHEMA.CourseInstance])
    course_instance_uri = results.first.subject
    assert_equal 1, results.count

    course_props = {}
    graph.query([course_uri, :p, :o]).each do |result|
      key = result.predicate.to_s.split('/').last
      course_props[key] ||= []
      course_props[key] << result.object.to_s
    end
    course_instance_props = {}
    graph.query([course_instance_uri, :p, :o]).each do |result|
      key = result.predicate.to_s.split('/').last
      course_instance_props[key] ||= []
      course_instance_props[key] << result.object.to_s
    end

    assert_equal ['Summer Course on Learning Stuff'], course_props['name']
    assert_equal ['Expand your horizons'], course_props['alternateName']
    assert_equal ['Learn lots of stuff!'], course_props['description']
    assert_equal ['http://example.com/cool-course-summer'], course_props['url']
    assert_equal ['Ruby', 'Javascript'].sort, course_props['keywords'].sort

    assert_equal ['2015-08-23 10:16:33 UTC'], course_instance_props['startDate']
    assert_equal ['2015-08-24 18:07:46 UTC'], course_instance_props['endDate']

    # Audience
    q = RDF::Query.new do
      pattern RDF::Query::Pattern.new(course_uri, RDF::Vocab::SCHEMA.audience, :audience_info)
      pattern RDF::Query::Pattern.new(:audience_info, RDF::Vocab::SCHEMA.audienceType, :target_audience)
    end

    results = graph.query(q)
    assert_equal 1, results.count
    assert_equal 'Everyone!', results.first.target_audience

    # ScientificTopics
    q = RDF::Query.new do
      pattern RDF::Query::Pattern.new(course_uri, RDF::Vocab::SCHEMA.about, :topic_info)
      pattern RDF::Query::Pattern.new(:topic_info, RDF::Vocab::SCHEMA.name, :scientific_topic_name)
    end
    results = graph.query(q)
    assert_equal 2, results.count
    topics = results.map(&:scientific_topic_name)
    assert_includes topics, 'Sequencing'
    assert_includes topics, 'Genetic variation'

    # Address
    q = RDF::Query.new do
      pattern RDF::Query::Pattern.new(course_instance_uri, RDF::Vocab::SCHEMA.location, :place)
      pattern RDF::Query::Pattern.new(:place, RDF::Vocab::SCHEMA.address, :address)
      pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.streetAddress, :street_address, optional: true)
      pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.addressLocality, :locality, optional: true)
      pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.addressRegion, :region, optional: true)
      pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.addressCountry, :country, optional: true)
      pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.postalCode, :postcode, optional: true)
      pattern RDF::Query::Pattern.new(:place, RDF::Vocab::SCHEMA.latitude, :latitude, optional: true)
      pattern RDF::Query::Pattern.new(:place, RDF::Vocab::SCHEMA.longitude, :longitude, optional: true)
    end
    results = graph.query(q)
    assert_equal 1, results.count
    assert_equal 'Kilburn Building', results.first.street_address
    assert_equal 'Manchester', results.first.locality
    assert_equal 'Greater Manchester', results.first.region
    assert_equal 'United Kingdom', results.first.country
    assert_equal 'M13 9PL', results.first.postcode
    assert_equal '53.467458', results.first.latitude
    assert_equal '-2.233949', results.first.longitude

    # Sponsors
    q = RDF::Query.new do
      pattern RDF::Query::Pattern.new(course_instance_uri, RDF::Vocab::SCHEMA.funder, :funder_info)
      pattern RDF::Query::Pattern.new(:funder_info, RDF::Vocab::SCHEMA.name, :funder)
    end
    results = graph.query(q)
    assert_equal 3, results.count
    sponsors = results.map(&:funder)
    assert_includes sponsors, 'Amazon'
    assert_includes sponsors, 'Google'
    assert_includes sponsors, 'GitHub'

    # Organizer
    q = RDF::Query.new do
      pattern RDF::Query::Pattern.new(course_instance_uri, RDF::Vocab::SCHEMA.organizer, :organizer_info)
      pattern RDF::Query::Pattern.new(:organizer_info, RDF::Vocab::SCHEMA.name, :organizer)
    end
    results = graph.query(q)
    assert_equal 1, results.count
    assert_equal 'CourseCo', results.first.organizer
  end

  test 'Bioschemas on event index page' do
    event = events(:training_event)
    course = events(:course_event)
    Event.where.not(id: [event.id, course.id]).destroy_all

    get events_path

    reader = RDF::Reader.for(:rdfa).new(response.body, base_uri: events_url, logger: false)
    graph = RDF::Graph.new
    graph.insert_statements(reader)

    results = graph.query([:subject, RDF.type, RDF::Vocab::SCHEMA.Event])
    assert_equal 1, results.count
    assert_equal event_url(event), results.first.subject.to_s

    results = graph.query([:subject, RDF.type, RDF::Vocab::SCHEMA.Course])
    assert_equal 1, results.count
    assert_equal event_url(course), results.first.subject.to_s
  end

  test 'LearningResource bioschemas on show page for material' do
    material = materials(:material_with_optionals)
    url = material_url(material.id)

    get url

    reader = RDF::Reader.for(:rdfa).new(response.body, base_uri: url, logger: false)
    graph = RDF::Graph.new
    graph.insert_statements(reader)

    results = graph.query([:subject, RDF.type, RDF::Vocab::SCHEMA.LearningResource])
    material_uri = results.first.subject
    assert_equal 1, results.count
    assert_equal url, material_uri
    props = {}
    graph.query([material_uri, :p, :o]).each do |result|
      key = result.predicate.to_s.split('/').last
      props[key] ||= []
      props[key] << result.object.to_s
    end
    assert_equal ['Training Material with All Optionals'], props['name']
    assert_equal ['This is a Training Material produced by an example organization'], props['description']
    assert_equal ['https://training.com/material/023'], props['url']
    assert_equal ['material','with','optionals'].sort, props['keywords'].sort
    assert_equal ['https://spdx.org/licenses/CC-BY-4.0.html'], props['license']
    assert_equal ['2021-07-12'], props['dateCreated']
    assert_equal ['2021-07-13'], props['dateModified']
    assert_equal ['intermediate'], props['educationalLevel']

    # Audience
    q = RDF::Query.new do
      pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.audience, :audience_info)
      pattern RDF::Query::Pattern.new(:audience_info, RDF::Vocab::SCHEMA.audienceType, :target_audience)
    end

    results = graph.query(q)
    assert_equal 2, results.count
    audiences = results.map(&:target_audience)
    assert_includes audiences, 'HDR'
    assert_includes audiences, 'ECR'

    # ScientificTopics
    q = RDF::Query.new do
      pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.about, :topic_info)
      pattern RDF::Query::Pattern.new(:topic_info, RDF::Vocab::SCHEMA.name, :scientific_topic_name)
    end
    results = graph.query(q)
    assert_equal 1, results.count
    topics = results.map(&:scientific_topic_name)
    assert_includes topics, 'Metabolomics'

    # Authors
    q = RDF::Query.new do
      pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.author, :author_info)
      pattern RDF::Query::Pattern.new(:author_info, RDF::Vocab::SCHEMA.name, :author)
    end
    results = graph.query(q)
    assert_equal 2, results.count
    authors = results.map(&:author)
    assert_includes authors, 'Nicolai Tesla'
    assert_includes authors, 'Thomas Edison'

    # Contributors
    q = RDF::Query.new do
      pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.contributor, :contributor_info)
      pattern RDF::Query::Pattern.new(:contributor_info, RDF::Vocab::SCHEMA.name, :contributor)
    end
    results = graph.query(q)
    assert_equal 1, results.count
    authors = results.map(&:contributor)
    assert_includes authors, 'Dr Dre'
  end

  test 'Bioschemas on material index page' do
    material = materials(:good_material)
    other_material = materials(:material_with_optionals)
    Material.where.not(id: [material.id, other_material.id]).destroy_all

    get materials_path

    reader = RDF::Reader.for(:rdfa).new(response.body, base_uri: materials_url, logger: false)
    graph = RDF::Graph.new
    graph.insert_statements(reader)

    results = graph.query([:subject, RDF.type, RDF::Vocab::SCHEMA.LearningResource])
    assert_equal 2, results.count
    assert_equal [material_url(material), material_url(other_material)].sort, results.map { |result| result.subject.to_s }.sort
  end
end
