require 'test_helper'
require 'sidekiq/testing'

class EventTest < ActiveSupport::TestCase

  test 'can get associated nodes for event' do
    e = events(:scraper_user_event)

    assert_equal [], e.nodes
    assert_equal 1, e.associated_nodes.count
    assert_includes e.associated_nodes, nodes(:good)
  end

  test 'can add a node to an event' do
    e = events(:scraper_user_event)

    assert_difference('NodeLink.count', 1) do
      e.nodes << nodes(:westeros)
    end

    assert_equal 1, e.nodes.count
    assert_includes e.nodes, nodes(:westeros)
    assert_equal 2, e.associated_nodes.count
    assert_includes e.associated_nodes, nodes(:good)
    assert_includes e.associated_nodes, nodes(:westeros)
  end

  test 'validates CV terms' do
    e = events(:scraper_user_event)
    e.event_types = ['warehouse rave']
    e.eligibility = ['cool dudes only']

    refute e.save
    assert_equal 2, e.errors.count
    assert_equal ['contained invalid terms: warehouse rave'], e.errors[:event_types]
    assert_equal ['contained invalid terms: cool dudes only'], e.errors[:eligibility]

    e.event_types = ['receptions_and_networking']
    e.eligibility = ['registration_of_interest']

    assert e.save
    assert_equal 0, e.errors.count
  end

  test 'node names/associated node names includes names of nodes' do
    e = events(:scraper_user_event)

    assert_includes e.associated_node_names, nodes(:good).name
    assert_not_includes e.node_names, nodes(:good).name

    e.nodes << nodes(:westeros)

    assert_includes e.associated_node_names, nodes(:good).name
    assert_includes e.associated_node_names, nodes(:westeros).name

    assert_not_includes e.node_names, nodes(:good).name
    assert_includes e.node_names, nodes(:westeros).name
  end

  test 'set default start time' do
    e = events(:event_with_no_start)
    assert_nil e.start
    e.save()
    assert_nil e.start
    e.start = '2016-11-22'
    e.save()
    assert_equal e.start.hour, 9

  end

  test 'set default end time' do
    time = Time.zone.parse('2016-11-22')
    e = events(:event_with_no_end)
    assert_equal e.start, time
    assert_nil e.end
    e.save()
    assert_equal e.start, time + 9.hours
    assert_equal e.end, time + 17.hours
  end

  test 'set default online end time' do
    time = Time.zone.parse('2016-11-22 14:00')
    e = events(:online_event_with_no_end)
    assert_equal e.start, time
    assert_nil e.end
    e.save()
    assert_equal e.start, time
    assert_equal e.end, time + 1.hours
  end

  test 'lower precedence content provider does not overwrite' do
    e = events(:organisation_event)

    assert_equal content_providers(:organisation_provider), e.content_provider

    e.content_provider = content_providers(:portal_provider)

    assert e.save
    assert_equal content_providers(:organisation_provider), e.reload.content_provider
  end

  test 'higher precedence content provider does overwrite' do
    e = events(:organisation_event)

    assert_equal content_providers(:organisation_provider), e.content_provider

    e.content_provider = content_providers(:project_provider)

    assert e.save
    assert_equal content_providers(:project_provider), e.content_provider
  end

  test 'equal precedence content provider does overwrite' do
    e = events(:portal_event)

    assert_equal content_providers(:portal_provider), e.content_provider

    e.content_provider = content_providers(:another_portal_provider)

    assert e.save
    assert_equal content_providers(:another_portal_provider), e.content_provider
  end

  test 'country name is corrected before save' do
    e = events(:dodgy_country_event)
    assert_equal e.country, 'üK'
    assert e.save
    assert_equal e.country, 'United Kingdom'
  end

  test 'destroys redundant scientific topic links' do
    e = events(:scraper_user_event)

    e.scientific_topic_names = ['Proteins', 'Chromosomes']
    e.save!
    assert_equal 2, e.scientific_topics.count

    assert_difference('OntologyTermLink.count', -2) do
      e.scientific_topic_names = []
      e.save!
    end
  end

  test 'does not add duplicate scientific topics' do
    e = events(:scraper_user_event)

    # Via names
    assert_difference('OntologyTermLink.count', 2) do
      e.scientific_topic_names = ['Proteins', 'Chromosomes', 'Proteins', 'Chromosomes']
      e.save!
      assert_equal 2, e.scientific_topics.count
    end

    assert_no_difference('OntologyTermLink.count') do
      e.scientific_topic_names = ['Proteins', 'Chromosomes']
      e.save!
      assert_equal 2, e.scientific_topics.count
    end

    # Via uris
    assert_difference('OntologyTermLink.count', -2) do
      e.scientific_topic_links.clear
    end

    assert_difference('OntologyTermLink.count', 2) do
      e.scientific_topic_uris = ['http://edamontology.org/topic_0078', 'http://edamontology.org/topic_0654',
                                  'http://edamontology.org/topic_0078', 'http://edamontology.org/topic_0654']
      e.save!
      assert_equal 2, e.scientific_topics.count
    end

    assert_no_difference('OntologyTermLink.count') do
      e.scientific_topic_uris = ['http://edamontology.org/topic_0078', 'http://edamontology.org/topic_0654']
      e.save!
      assert_equal 2, e.scientific_topics.count
    end

    # Via terms
    e.scientific_topic_links.clear

    proteins_term = EDAM::Ontology.instance.lookup('http://edamontology.org/topic_0078')
    chromosomes_term = EDAM::Ontology.instance.lookup('http://edamontology.org/topic_0624')

    assert_difference('OntologyTermLink.count', 2) do
      e.scientific_topics = [proteins_term, chromosomes_term, proteins_term, chromosomes_term]
      e.save!
    end

    assert_no_difference('OntologyTermLink.count') do
      e.scientific_topics = [proteins_term, chromosomes_term]
      e.save!
    end

    # All three
    assert_no_difference('OntologyTermLink.count') do
      e.scientific_topic_names = ['Proteins', 'Chromosomes']
      e.save!
    end

    assert_no_difference('OntologyTermLink.count') do
      e.scientific_topic_uris = ['http://edamontology.org/topic_0078', 'http://edamontology.org/topic_0654']
      e.save!
    end
  end

  test 'can check if an event has been reported on' do
    e = events(:scraper_user_event)

    refute e.reported?

    e.update_attribute(:funding, 'Selling lemonade')

    assert e.reported?
  end

  test 'can associate material with event' do
    event = events(:one)
    material = materials(:good_material)

    assert_difference('EventMaterial.count', 1) do
      event.materials << material
    end
  end

  test 'can delete an event with associated materials' do
    event = events(:one)
    material = materials(:good_material)
    event.materials << material

    assert_difference('EventMaterial.count', -1) do
      assert_difference('Event.count', -1) do
        assert_no_difference('Material.count') do
          event.destroy
        end
      end
    end
  end

  test 'can get/set lat/lon using geographic coordinates' do
    event = events(:two)

    assert_nil event.latitude
    assert_nil event.longitude
    assert_equal [nil, nil], event.geographic_coordinates

    event.geographic_coordinates = [14, 15]

    assert_equal 14, event.latitude
    assert_equal 15, event.longitude
    assert_equal [14, 15], event.geographic_coordinates
  end

  test 'blocks disallowed domain' do
    event = Event.new(user: users(:regular_user), title: 'Bad event', url: 'bad-domain.example/event')

    refute event.save

    assert_equal ['not valid'], event.errors[:url]
  end

  test 'does not block non-disallowed(?!) domain' do
    event = Event.new(user: users(:regular_user), title: 'Good event', url: 'good-domain.example/event')

    assert event.save

    assert event.errors[:url].empty?
  end

  test 'does not throw error when blocked domains list is blank' do
    domains = TeSS::Config.blocked_domains
    begin
      TeSS::Config.blocked_domains = nil
      assert_nothing_raised do
        Event.create!(user: users(:regular_user), title: 'Bad event', url: 'bad-domain.example/event')
      end
    ensure
      TeSS::Config.blocked_domains = domains
    end
  end

  test 'enqueues a geocoding worker after creating an event' do
    assert_difference('GeocodingWorker.jobs.size', 1) do
      event = Event.create(user: users(:regular_user), title: 'New event', url: 'http://example.com', venue: 'A place', city: 'Manchester')
      refute event.address.blank?
    end
  end

  test 'enqueues a geocoding worker after changing address' do
    event = events(:portal_event)
    event.venue = 'New Venue!'

    assert_difference('GeocodingWorker.jobs.size', 1) do
      event.save!
    end
  end

  test 'does not enqueue a geocoding worker after creating an event with no address' do
    assert_no_difference('GeocodingWorker.jobs.size') do
      event = Event.create(user: users(:regular_user), title: 'New event', url: 'http://example.com', online: true)
      assert event.address.blank?
    end
  end

  test 'does not enqueue a geocoding worker after creating an event with defined lat/lon' do
    assert_no_difference('GeocodingWorker.jobs.size') do
      event = Event.create(user: users(:regular_user), title: 'New event', url: 'http://example.com', latitude: 25, longitude: 25, venue: 'Place')
      refute event.address.blank?
    end
  end

  test 'does not enqueue a geocoding worker after changing a non-address field' do
    event = events(:portal_event)
    event.title = 'New title'
    refute event.address.blank?

    assert_no_difference('GeocodingWorker.jobs.size') do
      event.save!
    end
  end

  test 'does not enqueue a geocoding worker if the address is cached' do
    event = Event.new(user: users(:regular_user), title: 'New event', url: 'http://example.com', venue: 'A place', city: 'Manchester')
    redis = Redis.new
    redis.set(event.address, [45, 45].to_json)

    refute event.address.blank?

    assert_no_difference('GeocodingWorker.jobs.size') do
      event.save!
      assert_equal 45, event.latitude
      assert_equal 45, event.longitude
    end
  end
end
