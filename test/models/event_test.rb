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

    e.valid?
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
    e.save
    assert_nil e.start
    e.start = '2016-11-22'
    e.save
    assert_equal 9, e.start.hour
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

    e.scientific_topic_names = %w[Proteins Chromosomes]
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
      e.scientific_topic_names = %w[Proteins Chromosomes Proteins Chromosomes]
      e.save!
      assert_equal 2, e.scientific_topics.count
    end

    assert_no_difference('OntologyTermLink.count') do
      e.scientific_topic_names = %w[Proteins Chromosomes]
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

    proteins_term = Edam::Ontology.instance.lookup('http://edamontology.org/topic_0078')
    chromosomes_term = Edam::Ontology.instance.lookup('http://edamontology.org/topic_0624')

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
      e.scientific_topic_names = %w[Proteins Chromosomes]
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
    parameters = @mandatory.merge({ user: users(:regular_user), title: 'Bad event', url: 'https://bad-domain.example/event',
                                    online: true })
    event = Event.new(parameters)

    refute event.save
    assert event.errors.added?(:url, 'not valid')
  end

  test 'does not block non-disallowed(?!) domain' do
    parameters = @mandatory.merge({ user: users(:regular_user), title: 'Good event', url: 'http://good-domain.example/event',
                                    description: 'event for does not block non-disallowed domain', online: true })
    event = Event.new(parameters)

    assert event.save
    assert event.errors[:url].empty?
  end

  test 'does not throw error when blocked domains list is blank' do
    with_settings(blocked_domains: nil) do
      assert_nothing_raised do
        parameters = @mandatory.merge({ user: users(:regular_user), title: 'Bad event', url: 'https://bad-domain.example/event',
                                        description: 'event for does not throw error when blocked domains list is blank',
                                        online: true })
        Event.create!(parameters)
      end
    end
  end

  test 'enqueues a geocoding worker after creating an event' do
    assert_difference('GeocodingWorker.jobs.size', 1) do
      parameters = @mandatory.merge({ user: users(:regular_user), title: 'New event', url: 'http://example.com',
                                      online: false, description: 'event to test enqueing of geocoding worker',
                                      venue: 'A place', city: 'Manchester', country: 'UK', postcode: 'M16 0TH' })
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
    assert_operator event.nominatim_count, :<, Event::NOMINATIM_MAX_ATTEMPTS, 'nominatim count too high'

    assert_no_difference('GeocodingWorker.jobs.size') do
      event.save!
    end
  end

  test 'does not enqueue a geocoding worker if the address is cached' do
    parameters = @mandatory.merge({ user: users(:regular_user), title: 'New event', url: 'http://example.com',
                                    online: false, description: 'event for geocoding enqueue test',
                                    venue: 'A place', city: 'Manchester',
                                    country: @event.country, postcode: @event.postcode })
    event = Event.new(parameters)
    redis = Redis.new(url: TeSS::Config.redis_url)
    redis.set(event.address, [45, 45].to_json)

    refute event.address.blank?

    assert_no_difference('GeocodingWorker.jobs.size') do
      event.save!
      assert_equal 45, event.latitude
      assert_equal 45, event.longitude
    end
  end

  test 'can set a valid duration for event' do
    valid_duration = '01:15'
    e = events(:one)
    e.duration = valid_duration
    e.save
    assert_equal 0, e.errors[:duration].size, 'unexpected validation error: ' + e.errors[:duration].to_s
  end

  test 'cannot set an invalid duration for event' do
    invalid_duration = 'One hour 99 minutes'
    e = events(:one)
    e.duration = invalid_duration
    e.save
    # issue 172 - changed duration to allow free text
    assert_equal 0, e.errors[:duration].size, 'unexpected number of validation errors: ' + e.errors[:duration].size.to_s
    # assert_equal "must be in format HH:MM", e.errors[:duration][0]
  end

  test 'can set an duration for event longer than one day' do
    valid_duration = '25:00'
    e = events(:one)
    e.duration = valid_duration
    e.save
    assert_equal 0, e.errors[:duration].size, 'unexpected validation error: ' + e.errors[:duration].to_s
  end

  test 'duration validation boundary testing' do
    # issue 172 - changed duration to allow free text
    durations = [
      { dvalue: '00:00', passed: true },
      { dvalue: '99:00', passed: true },
      { dvalue: '99:59', passed: true },
      { dvalue: '00:59', passed: true },
      { dvalue: '23:30', passed: true },
      { dvalue: '', passed: true },
      { dvalue: '-00:00', passed: true },
      { dvalue: '9:9', passed: true },
      { dvalue: '100:00', passed: true },
      { dvalue: '00:60', passed: true },
      { dvalue: '00:99', passed: true }
    ]

    e = events(:one)
    durations.each do |t|
      # puts "\n testing value[#{t[:dvalue]}] passed[#{t[:passed]}]"
      e.duration = t[:dvalue]
      e.save
      if t[:passed]
        assert_equal 0, e.errors[:duration].size, "unexpected validation error of #{t[:dvalue]}: " + e.errors[:duration].to_s
      else
        assert_equal 1, e.errors[:duration].size, "expected validation error of #{t[:dvalue]}: " + e.errors[:duration].to_s
      end
    end
  end

  test 'validates timezone if present' do
    event = Event.new(title: 'An event', url: 'https://myevent.com', timezone: 'UTC', user: users(:regular_user))
    assert event.valid?

    event.timezone = '123'
    refute event.valid?
    assert event.errors.added?(:timezone, 'not found and cannot be linked to a valid timezone')

    event.timezone = nil
    assert event.valid?

    event.timezone = ''
    assert event.valid?
  end

  test 'validates language if present' do
    event = Event.new(title: 'An event', url: 'https://myevent.com', language: 'en', user: users(:regular_user))
    assert event.valid?

    # Okay if not present
    event.language = nil
    assert event.valid?

    # Okay if blank
    event.language = ''
    assert event.valid?

    # Not okay if not a known ISO-639-2 code
    event.language = 'yo'
    refute event.valid?
    assert event.errors.added?(:language, 'must be a controlled vocabulary term')
  end

  test 'validates URL format' do
    event = Event.new(title: 'An event', timezone: 'UTC', user: users(:regular_user))

    refute event.valid?
    assert event.errors.added?(:url, :blank)

    event.url = '123'
    refute event.valid?
    assert event.errors.added?(:url, :url, value: '123')

    event.url = '/relative'
    refute event.valid?
    assert event.errors.added?(:url, :url, value: '/relative')

    event.url = 'git://something.git'
    refute event.valid?
    assert event.errors.added?(:url, :url, value: 'git://something.git')

    event.url = 'http://http-website.com/mat'
    assert event.valid?
    refute event.errors.added?(:url, :url, value: 'http://http-website.com/mat')

    event.url = 'https://https-website.com/mat'
    assert event.valid?
    refute event.errors.added?(:url, :url, value: 'https://https-website.com/mat')

    event.url = 'ftp://something/something'
    refute event.valid?
    assert event.errors.added?(:url, :url, value: 'ftp://something/something')
  end

  test 'fuzzy-matches event types according to dictionary' do
    event = Event.new(title: 'An event', timezone: 'UTC', user: users(:regular_user), url: 'https://https-website.com/mat')
    assert event.valid?

    eligibility = EligibilityDictionary.instance.keys.first
    # ensure a ~50% match
    event.eligibility = [eligibility[0..(eligibility.length / 2)]]
    assert event.valid?
    assert_equal [eligibility], event.eligibility

    event_type = EventTypeDictionary.instance.keys.first
    event.event_types = [event_type[0..(event_type.length / 2)]]
    assert event.valid?
    assert_equal [event_type], event.event_types
  end

  test 'get online status from description if scraped' do
    event = Event.new(title: 'An event', timezone: 'UTC', user: users(:regular_user), url: 'https://https-website.com/mat',
                      description: 'This event is held on Zoom', scraper_record: true)
    refute event.online?
    assert event.valid?
    event.save!
    assert event.online?
  end

  test 'do not fix online status if hybrid' do
    event = Event.new(title: 'An event', timezone: 'UTC', user: users(:regular_user), url: 'https://https-website.com/mat',
                      description: 'This event is held on Zoom', scraper_record: true, presence: :hybrid)
    assert event.hybrid?
    assert event.valid?
    event.save!
    assert event.hybrid?
  end

  test 'get event_type from keywords if scraped' do
    event = Event.new(title: 'An event', timezone: 'UTC', user: users(:regular_user), url: 'https://https-website.com/mat',
                      keywords: ['Workshops and courses'], scraper_record: true)
    assert_not event.event_types.include?('Workshops and courses')
    assert event.keywords.include?('Workshops and courses')
    assert event.valid?
    event.save!
    assert event.event_types.include?('workshops_and_courses')
    assert_not event.keywords.include?('Workshops and courses')
  end

  test 'do not get event_type from keywords if not scraped' do
    event = Event.new(title: 'An event', timezone: 'UTC', user: users(:regular_user), url: 'https://https-website.com/mat',
                      keywords: ['Workshops and courses'], scraper_record: false)
    assert event.valid?
    event.save!
    assert_not event.event_types.include?('Workshops and courses')
    assert event.keywords.include?('Workshops and courses')
  end

  test 'duplicate' do
    user = users(:regular_user)
    node = nodes(:westeros)
    material = materials(:good_material)
    event = Event.new(
      title: 'An event',
      timezone: 'UTC',
      user:,
      url: 'https://events.com/1',
      keywords: ['fun times'],
      nodes: [node],
      external_resources_attributes: { '0' => { title: 'test', url: 'https://external-resource.com' } },
      materials: [material],
      scientific_topic_names: %w[Proteins DNA],
      operation_names: ['Variant calling']
    )

    assert event.save
    dup = nil
    assert event.slug

    # Duplicating should not create any records
    assert_no_difference('Event.count') do
      assert_no_difference('OntologyTermLink.count') do
        assert_no_difference('NodeLink.count') do
          assert_no_difference('ExternalResource.count') do
            assert_no_difference('EventMaterial.count') do
              dup = event.duplicate

              assert_equal 'An event', dup.title
              assert_equal 'UTC', dup.timezone
              assert_nil dup.id
              assert_nil dup.slug
              assert_nil dup.url
              assert_equal [material], dup.materials
              assert_equal [node], dup.nodes
              assert_equal %w[Proteins DNA], dup.scientific_topic_names
              assert_equal ['Variant calling'], dup.operation_names
              assert_equal 1, dup.external_resources.length
              assert_equal 'test', dup.external_resources.first.title
              assert_equal 'https://external-resource.com', dup.external_resources.first.url
            end
          end
        end
      end
    end

    # Records are created when duplicate is saved
    assert_difference('Event.count', 1) do
      assert_difference('OntologyTermLink.count', 3) do
        assert_difference('NodeLink.count', 1) do
          assert_difference('ExternalResource.count', 1) do
            assert_difference('EventMaterial.count', 1) do
              dup.url = 'https://events.com/2'
              assert dup.save
            end
          end
        end
      end
    end
  end

  test 'should strip attributes' do
    assert @event.update(title: ' Event  Title  ', url: " https://event.com\n")
    assert_equal 'Event  Title', @event.title
    assert_equal 'https://event.com', @event.url
  end

  test 'show_map?' do
    assert TeSS::Config.map_enabled

    assert events(:one).show_map?
    refute events(:portal_event).show_map?
    assert events(:kilburn).suggested_latitude
    assert events(:kilburn).show_map?

    with_settings(feature: { disabled: ['events_map'] }) do
      refute TeSS::Config.map_enabled
      refute events(:one).show_map?
    end
  end

  test 'can still set presence through online setter' do
    assert @event.valid?
    assert @event.onsite?
    refute @event.online?
    refute @event.hybrid?

    @event.online = true

    assert @event.valid?
    refute @event.onsite?
    assert @event.online?
    refute @event.hybrid?

    @event.online = false

    assert @event.valid?
    assert @event.onsite?
    refute @event.online?
    refute @event.hybrid?

    @event.online = ''

    assert @event.valid?
    assert @event.onsite?
    refute @event.online?
    refute @event.hybrid?
  end

  test 'validates presence' do
    @event.presence = 'onsite'

    assert @event.valid?
    assert @event.onsite?
    refute @event.online?
    refute @event.hybrid?

    @event.presence = 0

    assert @event.valid?
    assert @event.onsite?
    refute @event.online?
    refute @event.hybrid?

    @event.presence = :online

    assert @event.valid?
    refute @event.onsite?
    assert @event.online?
    refute @event.hybrid?

    @event.presence = 1

    assert @event.valid?
    refute @event.onsite?
    assert @event.online?
    refute @event.hybrid?

    @event.presence = 'hybrid'

    assert @event.valid?
    refute @event.onsite?
    refute @event.online?
    assert @event.hybrid?

    @event.presence = nil

    assert @event.valid?
    assert @event.onsite?
    refute @event.online?
    refute @event.hybrid?

    @event.presence = ''

    assert @event.valid?
    assert @event.onsite?
    refute @event.online?
    refute @event.hybrid?

    # TODO: Use enum validation in Rails 7.1 https://github.com/rails/rails/pull/49100
    assert_raises(ArgumentError) do
      @event.presence = 'xyz'
      refute @event.valid?
    end
  end

  test 'scientific_topics_and_synonyms' do
    @event.scientific_topic_names = ['Data management']
    @event.save!
    assert_equal ['Data management', 'Metadata management', 'Research data management (RDM)'], @event.reload.scientific_topics_and_synonyms

    @event.scientific_topic_names = ['Data management', 'Metadata management', 'Research data management (RDM)']
    @event.save!
    assert_equal ['Data management', 'Metadata management', 'Research data management (RDM)'], @event.reload.scientific_topics_and_synonyms
  end

  test 'operations_and_synonyms' do
    @event.operation_names = ['Fold recognition', 'Fold prediction']
    @event.save!
    assert_equal ['Fold recognition', 'Domain prediction', 'Fold prediction', 'Protein domain prediction',
                  'Protein fold prediction', 'Protein fold recognition'], @event.reload.operations_and_synonyms
  end

  test 'can add an llm_interaction to an event' do
    e = events(:scraper_user_event)
    l = llm_interactions(:scrape)
    e.llm_interaction = l
    e.save!
    assert_equal e.llm_interaction.id, l.id
    assert_equal l.event_id, e.id
  end

  test 'can destroy an llm_interaction with an event' do
    e = events(:scraper_user_event)
    l = llm_interactions(:scrape)
    e.llm_interaction = l
    e.save!
    assert_difference 'LlmInteraction.count', -1 do
      e.destroy!
    end
  end
end
