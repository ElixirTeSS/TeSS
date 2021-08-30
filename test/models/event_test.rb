require 'test_helper'
require 'sidekiq/testing'

class EventTest < ActiveSupport::TestCase

  setup do
    @event = events(:one)
    @mandatory = { start: @event.start, end: @event.end, organizer: @event.organizer,
                   timezone: @event.timezone, contact: @event.contact, eligibility: @event.eligibility,
                   host_institutions: @event.host_institutions }
  end

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
    assert_equal 0, e.start.hour

  end

  test 'set default end time' do
    time = Time.zone.parse('2016-11-22')
    e = events(:event_with_no_end)
    assert_equal e.start, time
    assert_nil e.end
    e.save()
    # end time is now mandatory
    assert !e.errors[:end].empty?
    assert e.errors[:end].size == 1
    assert_equal e.errors[:end][0].to_s, "can't be blank"

    #assert_equal e.start, time + 9.hours
    #assert_equal e.end, time + 17.hours
  end

  test 'set default online end time' do
    time = Time.zone.parse('2016-11-22 14:00')
    e = events(:online_event_with_no_end)
    assert_equal e.start, time
    assert_nil e.end
    e.save()
    # end time is now mandatory
    assert !e.errors[:end].empty?
    assert e.errors[:end].size == 1
    assert_equal e.errors[:end][0].to_s, "can't be blank"

    #assert_equal e.start, time
    #assert_equal e.end, time + 1.hours
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
    parameters = @mandatory.merge({ user: users(:regular_user), title: 'Bad event', url: 'bad-domain.example/event',
                                    online: true })
    event = Event.new(parameters)

    refute event.save

    assert_equal ['not valid'], event.errors[:url]
  end

  test 'does not block non-disallowed(?!) domain' do
    parameters = @mandatory.merge({ user: users(:regular_user), title: 'Good event', url: 'good-domain.example/event',
                                    description: "event for does not block non-disallowed domain", online: true })
    event = Event.new(parameters)

    assert event.save

    assert event.errors[:url].empty?
  end

  test 'does not throw error when blocked domains list is blank' do
    domains = TeSS::Config.blocked_domains
    begin
      TeSS::Config.blocked_domains = nil
      assert_nothing_raised do
        parameters = @mandatory.merge({ user: users(:regular_user), title: 'Bad event', url: 'bad-domain.example/event',
                                        description: "event for does not throw error when blocked domains list is blank",
                                        online: true })
        Event.create!(parameters)
      end
    ensure
      TeSS::Config.blocked_domains = domains
    end
  end

  test 'enqueues a geocoding worker after creating an event' do
    assert_difference('GeocodingWorker.jobs.size', 1) do
      parameters = @mandatory.merge({ user: users(:regular_user), title: 'New event', url: 'http://example.com',
                                      online: false, description: "event to test enqueing of geocoding worker",
                                      venue: 'A place', city: 'Manchester', country: 'UK', postcode: 'M16 0TH'
                                    })
      event = Event.create(parameters)
      assert event.errors[:url].empty?
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
      event = Event.create(user: users(:regular_user), title: 'New event', url: 'http://example.com',
                           latitude: 25, longitude: 25, venue: 'Place')
      refute event.address.blank?
    end
  end

  test 'does not enqueue a geocoding worker after changing a non-address field' do
    event = events(:portal_event)
    event.title = 'New title'

    refute event.address.blank?
    refute event.postcode.blank?
    refute event.latitude.present?
    refute event.longitude.present?
    assert_operator event.nominatim_count, :<, Event::NOMINATIM_MAX_ATTEMPTS, "nominatim count too high"

    assert_no_difference('GeocodingWorker.jobs.size') do
      event.save!
    end
  end

  test 'does not enqueue a geocoding worker if the address is cached' do
    parameters = @mandatory.merge({ user: users(:regular_user), title: 'New event', url: 'http://example.com',
                                    online: false, description: "event for geocoding enqueue test",
                                    venue: 'A place', city: 'Manchester',
                                    country: @event.country, postcode: @event.postcode })
    event = Event.new(parameters)
    redis = Redis.new
    redis.set(event.address, [45, 45].to_json)

    refute event.address.blank?

    assert_no_difference('GeocodingWorker.jobs.size') do
      event.save!
      assert_equal 45, event.latitude
      assert_equal 45, event.longitude
    end
  end

  test 'can set a valid duration for event' do
    valid_duration = "01:15"
    e = events(:one)
    e.duration = valid_duration
    e.save()
    assert_equal 0, e.errors[:duration].size, "unexpected validation error: " + e.errors[:duration].to_s
  end

  test 'cannot set an invalid duration for event' do
    invalid_duration = "One hour 99 minutes"
    e = events(:one)
    e.duration = invalid_duration
    e.save()
    # issue 172 - changed duration to allow free text
    assert_equal 0, e.errors[:duration].size, "unexpected number of validation errors: " + e.errors[:duration].size.to_s
    # assert_equal "must be in format HH:MM", e.errors[:duration][0]
  end

  test 'can set an duration for event longer than one day' do
    valid_duration = "25:00"
    e = events(:one)
    e.duration = valid_duration
    e.save()
    assert_equal 0, e.errors[:duration].size, "unexpected validation error: " + e.errors[:duration].to_s
  end

  test 'duration validation boundary testing' do
    # issue 172 - changed duration to allow free text
    durations = [
      {dvalue: '00:00', passed: true },
      {dvalue: '99:00', passed: true },
      {dvalue: '99:59', passed: true },
      {dvalue: '00:59', passed: true },
      {dvalue: '23:30', passed: true },
      {dvalue: '', passed: true },
      {dvalue: '-00:00', passed: true },
      {dvalue: '9:9', passed: true },
      {dvalue: '100:00', passed: true },
      {dvalue: '00:60', passed: true },
      {dvalue: '00:99', passed: true }
    ]

    e = events(:one)
    durations.each do |t|
      #puts "\n testing value[#{t[:dvalue]}] passed[#{t[:passed]}]"
      e.duration = t[:dvalue]
      e.save()
      if t[:passed]
        assert_equal 0, e.errors[:duration].size, "unexpected validation error of #{t[:dvalue]}: " + e.errors[:duration].to_s
      else
        assert_equal 1, e.errors[:duration].size, "expected validation error of #{t[:dvalue]}: " + e.errors[:duration].to_s
      end
    end

  end

end
