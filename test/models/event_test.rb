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

end
