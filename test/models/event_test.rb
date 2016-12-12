require 'test_helper'

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

    e.content_provider = content_providers(:iann)

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
    e = events(:iann_event)

    assert_equal content_providers(:iann), e.content_provider

    e.content_provider = content_providers(:goblet)

    assert e.save
    assert_equal content_providers(:goblet), e.content_provider
  end

end
