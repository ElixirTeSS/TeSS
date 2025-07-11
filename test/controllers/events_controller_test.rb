require 'test_helper'
require 'icalendar'
require 'rss'

class EventsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    mock_images
    @event = events(:one)
    @material = materials(:good_material)
    @collection = collections(:two)
    u = users(:regular_user)
    @event.user = u
    @event.save!
    @updated_event = {
      title: 'New title',
      description: 'New description'
    }
    @failing_event = events(:failing_event)
    @failing_event.title = 'Fail!'
    @monitor = @failing_event.create_link_monitor(url: @failing_event.url, code: 404, fail_count: 5)
    @mandatory_fields = { online: true, start: @event.start, end: @event.end, organizer: @event.organizer,
                          host_institutions: @event.host_institutions, timezone: @event.timezone,
                          contact: @event.contact, eligibility: @event.eligibility }
  end

  # Tests
  # INDEX, NEW, EDIT, CREATE, SHOW, BREADCRUMBS, TABS, API CHECKS

  # INDEX TESTS
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:events)
  end

  test 'should get index with solr enabled' do
    with_settings(solr_enabled: true) do
      Event.stub(:search_and_filter, MockSearch.new(Event.all)) do
        get :index, params: { q: 'nightclub', keywords: 'ragtime' }
        assert_response :success
        assert_not_empty assigns(:events)
      end
    end
  end

  test 'should render a calendar' do
    with_settings(solr_enabled: true) do
      Event.stub(:search_and_filter, MockSearch.new(Event.all)) do
        get :calendar
        assert_response :success
        assert_not_empty assigns(:events)
      end
    end
  end

  test 'should render a calendar into a JS update command' do
    with_settings(solr_enabled: true) do
      Event.stub(:search_and_filter, MockSearch.new(Event.all)) do
        get :calendar, format: :js, xhr: true
        assert_response :success
        assert_not_empty assigns(:events)
      end
    end
  end

  test 'should get index as json' do
    @event.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @event.save!

    get :index, params: { format: :json }
    assert_response :success
    assert_not_nil assigns(:events)
    assert_valid_legacy_json_response
  end

  test 'should get index as ICS' do
    @event.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @event.save!

    get :index, params: { format: :ics }
    assert_response :success
    assert_not_nil assigns(:events)
  end

  test 'should get index as RSS' do
    @event.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @event.save!

    get :index, params: { format: :rss }
    assert_response :success
    assert_not_nil assigns(:events)
  end

  test 'should get index as json-api' do
    @event.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @event.save!

    get :index, params: { format: :json_api }
    assert_response :success
    assert_not_nil assigns(:events)
    assert_valid_json_api_response

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert body['data'].any?
    assert body['meta']['results-count'] > 0
    assert body['meta'].key?('query')
    assert body['meta'].key?('facets')
    assert body['meta'].key?('available-facets')
    assert_equal events_path, body['links']['self']
  end

  test 'admins should be able to directly load failing records' do
    sign_in users(:admin)
    get :show, params: { id: @failing_event }
    assert_response :success
  end

  test 'regular users should be able to directly load failing records and see warning' do
    sign_in users(:regular_user)
    @monitor.update(failed_at: DateTime.new(2003, 12, 5))
    get :show, params: { id: @failing_event }
    assert_response :success
    assert_select '.broken-link-notice', text: /this event's URL.+since 5 December 2003/
  end

  # NEW TESTS
  test 'should get new' do
    sign_in users(:regular_user)
    get :new
    assert_response :success
  end

  test 'should get new page for logged in users only' do
    # Redirect to login if not logged in
    get :new
    assert_response :redirect
    sign_in users(:regular_user)
    # Success for everyone else
    get :new
    assert_response :success
    sign_in users(:admin)
    get :new
    assert_response :success
  end

  test 'should not get new page for basic users' do
    sign_in users(:basic_user)
    get :new
    assert_response :forbidden
  end

  # EDIT TESTS
  test 'should not get edit page for not logged in users' do
    # Not logged in = Redirect to login
    get :edit, params: { id: @event }
    assert_redirected_to new_user_session_path
  end

  # logged in but insufficient permissions = ERROR
  test 'should get edit for event owner' do
    sign_in @event.user
    get :edit, params: { id: @event }
    assert_response :success
  end

  test 'should get edit for admin' do
    # Owner of event logged in = SUCCESS
    sign_in users(:admin)
    get :edit, params: { id: @event }
    assert_response :success
  end

  test 'should get edit for curator' do
    sign_in users(:curator)
    get :edit, params: { id: @event }
    assert_response :success
  end

  test 'should get edit for content provider owner' do
    event = events(:scraper_user_event)
    user = event.content_provider.user

    sign_in user
    get :edit, params: { id: event }
    assert_response :success
  end

  test 'should not get edit page for non-owner user' do
    sign_in users(:another_regular_user)
    get :edit, params: { id: @event }
    assert :forbidden
  end

  test 'should get edit page for approved editor' do
    # add to approved editors and check
    @event.content_provider.add_editor users(:another_regular_user)
    sign_in users(:another_regular_user)
    get :edit, params: { id: @event }
    assert_response :success
  end

  # CREATE TEST
  test 'should create online event for user' do
    sign_in users(:regular_user)
    assert_difference('Event.count') do
      # Create event with all mandatory fields
      post :create, params: { event: { description: @event.description, title: @event.title, url: @event.url,
                                       duration: @event.duration, recognition: @event.recognition,
                                       learning_objectives: @event.learning_objectives }.merge(@mandatory_fields) }
    end
    assert_redirected_to event_path(assigns(:event))
    # check new fields: migration 5.2
    assert_not_nil assigns(:event), 'event is nil'
    assert_not_nil assigns(:event).duration, 'duration is nil'
    assert_equal @event.duration, assigns(:event).duration, 'duration not matched'
    assert_not_nil assigns(:event).recognition, 'recognition is nil'
    assert_equal @event.recognition, assigns(:event).recognition, 'recognition not matched'
    assert_not_nil assigns(:event).learning_objectives, 'learning objectives is nil'
    assert_equal @event.learning_objectives, assigns(:event).learning_objectives, 'learning objectives not matched'
  end

  test 'should create event for admin' do
    sign_in users(:admin)
    assert_difference('Event.count') do
      post :create, params: { event: { description: @event.description, title: @event.title, url: @event.url }.merge(@mandatory_fields) }
    end
    assert_redirected_to event_path(assigns(:event))
  end

  test 'should not create event for non-logged in user' do
    assert_no_difference('Event.count') do
      post :create, params: { event: { description: @event.description, title: @event.title, url: @event.url }.merge(@mandatory_fields) }
    end
    assert_redirected_to new_user_session_path
  end

  # SHOW TEST
  test 'should show event' do
    get :show, params: { id: @event }
    assert_response :success
    assert assigns(:event)
    assert_equal 'text/html; charset=utf-8', response.content_type, 'response content_type not matched.'
    assert_select '.broken-link-notice', count: 0
  end

  test 'should show all-day event' do
    get :show, params: { id: events(:two) }
    assert_response :success
    assert assigns(:event)
    assert_equal 'text/html; charset=utf-8', response.content_type, 'response content_type not matched.'
  end

  test 'should show event as json' do
    @event.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @event.save!

    get :show, params: { id: @event, format: :json }
    assert_response :success
    assert assigns(:event)
    assert_valid_legacy_json_response
  end

  test 'should show hybrid event as json' do
    event = events(:hybrid_event)

    get :show, params: { id: event, format: :json }
    assert_response :success
    assert assigns(:event)
    assert_valid_legacy_json_response

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert_equal true, body['online']
  end

  test 'should show event as json-api' do
    @event.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @event.materials << @material
    @event.collections << @collection
    @event.save!

    get :show, params: { id: @event, format: :json_api }
    assert_response :success
    assert assigns(:event)
    assert_valid_json_api_response

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert_equal @event.title, body['data']['attributes']['title']
    assert_equal @event.scientific_topic_uris.first, body['data']['attributes']['scientific-topics'].first['uri']
    assert_equal event_path(assigns(:event)), body['data']['links']['self']
    assert_equal @material.id.to_s, body['data']['relationships']['materials']['data'][0]['id']
    assert_equal @collection.id.to_s, body['data']['relationships']['collections']['data'][0]['id']
    assert_equal 'application/vnd.api+json; charset=utf-8', response.content_type, 'response content_type not matched.'
  end

  test 'should show hybrid event as json-api' do
    event = events(:hybrid_event)

    get :show, params: { id: event, format: :json_api }
    assert_response :success
    assert assigns(:event)
    assert_valid_json_api_response

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert_equal true, body['data']['attributes']['online']
    assert_equal 'hybrid', body['data']['attributes']['presence']
  end

  # UPDATE TEST
  test 'should update event' do
    sign_in @event.user
    patch :update, params: { id: @event, event: @updated_event }
    assert_redirected_to event_path(assigns(:event))
  end

  test 'should update event if curator' do
    sign_in users(:curator)
    assert_not_equal @event.user, users(:curator)
    patch :update, params: { id: @event, event: @updated_event }
    assert_redirected_to event_path(assigns(:event))
  end

  test 'should update event if content provider owner' do
    event = events(:scraper_user_event)
    user = event.content_provider.user

    assert_not_equal event.user, user
    assert_equal event.content_provider.user, user

    sign_in user

    patch :update, params: { id: event, event: @updated_event }

    assert_redirected_to event_path(assigns(:event))
  end

  test 'should not update event if not owner or curator etc.' do
    sign_in users(:collaborative_user)
    assert_not_equal @event.user, users(:collaborative_user)
    patch :update, params: { id: @event, event: @updated_event }
    assert_response :forbidden
  end

  # DESTROY TESTS
  test 'should destroy event owned by user' do
    sign_in @event.user
    assert_difference('Event.count', -1) do
      delete :destroy, params: { id: @event }
    end
    assert_redirected_to events_path
  end

  test 'should destroy event when administrator' do
    sign_in users(:admin)
    assert_difference('Event.count', -1) do
      delete :destroy, params: { id: @event }
    end
    assert_redirected_to events_path
  end

  test 'should destroy event when curator' do
    sign_in users(:curator)
    assert_difference('Event.count', -1) do
      delete :destroy, params: { id: @event }
    end
    assert_redirected_to events_path
  end

  test 'should destroy event when content provider owner' do
    event = events(:scraper_user_event)
    user = event.content_provider.user

    sign_in user
    assert_difference('Event.count', -1) do
      delete :destroy, params: { id: event }
    end
    assert_redirected_to events_path
  end

  test 'should destroy event when approved editor' do
    @event.content_provider.add_editor users(:another_regular_user)
    sign_in users(:another_regular_user)
    assert_difference('Event.count', -1) do
      delete :destroy, params: { id: @event }
    end
    assert_redirected_to events_path
  end

  test 'should not destroy event not owned by user' do
    sign_in users(:another_regular_user)
    assert_no_difference('Event.count') do
      delete :destroy, params: { id: @event }
    end
    assert_response :forbidden
  end

  # CONTENT TESTS
  # BREADCRUMBS
  test 'breadcrumbs for events index' do
    get :index
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li[class=active]', text: /Events/, count: 1
    end
  end

  test 'breadcrumbs for showing event' do
    get :show, params: { id: @event }
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li', text: /Events/, count: 1 do
        assert_select 'a[href=?]', events_url, count: 1
      end
      assert_select 'li[class=active]', text: /#{@event.title}/, count: 1
    end
  end

  test 'breadcrumbs for editing event' do
    sign_in users(:admin)
    get :edit, params: { id: @event }
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li', text: /Events/, count: 1 do
        assert_select 'a[href=?]', events_url, count: 1
      end
      assert_select 'li', text: /#{@event.title}/, count: 1 do
        assert_select 'a[href=?]', event_url(@event), count: 1
      end
      assert_select 'li[class=active]', text: /Edit/, count: 1
    end
  end

  test 'breadcrumbs for creating new event' do
    sign_in users(:regular_user)
    get :new
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'li', text: /Events/, count: 1 do
        assert_select 'a[href=?]', events_url, count: 1
      end
      assert_select 'li[class=active]', text: /New/, count: 1
    end
  end

  # OTHER CONTENT
  test 'event has correct layout' do
    get :show, params: { id: @event }
    assert_response :success
    assert_select 'h2', text: @event.title # Has Title
    assert_select 'a.btn', text: 'View event', count: 1 do
      assert_select 'a[href=?]', @event.url, count: 1
    end
    # Should not show when not logged in
    assert_select 'a.btn[href=?]', edit_event_path(@event), count: 0 # No Edit
    assert_select 'a.btn[href=?]', event_path(@event), count: 0 # No Edit
  end

  test 'do not show action buttons when not owner or admin' do
    sign_in users(:another_regular_user)
    get :show, params: { id: @event }
    assert_select 'a.btn[href=?]', edit_event_path(@event), count: 0 # No Edit
    assert_select 'a.btn[href=?]', event_path(@event), count: 0 # No Edit
  end

  test 'should show action buttons when owner' do
    sign_in @event.user
    get :show, params: { id: @event }
    assert_select 'a.btn[href=?]', edit_event_path(@event), count: 1
    assert_select 'a.btn[href=?]', event_path(@event), text: 'Delete', count: 1
  end

  test 'should show action buttons when approved editor' do
    @event.content_provider.add_editor users(:another_regular_user)
    sign_in users(:another_regular_user)
    get :show, params: { id: @event }
    assert_select 'a.btn[href=?]', edit_event_path(@event), count: 1
    assert_select 'a.btn[href=?]', event_path(@event), text: 'Delete', count: 1
  end

  test 'should show action buttons when admin' do
    sign_in users(:admin)
    get :show, params: { id: @event }
    assert_select 'a.btn[href=?]', edit_event_path(@event), count: 1
    assert_select 'a.btn[href=?]', event_path(@event), text: 'Delete', count: 1
  end

  test 'should hide disabled fields' do
    sign_in users(:regular_user)

    get :show, params: { id: @event }
    assert_response :success
    assert_select '#home' do
      assert_select '.text-primary', text: 'Organizer:', count: 1
      assert_select '.text-primary', text: 'Keywords:', count: 1
      assert_select '.text-primary', text: 'Contact:', count: 1
      assert_select '.text-primary', text: 'Sponsors:', count: 1
    end

    with_settings(feature: { disabled: %w[organizer keywords contact sponsors] }) do
      get :show, params: { id: @event }
      assert_response :success
      assert_select '#home' do
        assert_select '.text-primary', text: 'Organizer:', count: 0
        assert_select '.text-primary', text: 'Keywords:', count: 0
        assert_select '.text-primary', text: 'Contact:', count: 0
        assert_select '.text-primary', text: 'Sponsors:', count: 0
      end
    end
  end

  # API Actions
  test 'should find existing event by title, content provider and date' do
    post :check_exists, params: { format: :json, event: { title: @event.title,
                                                          url: 'whatever.com',
                                                          content_provider_id: @event.content_provider_id,
                                                          start: @event.start } }
    assert_response :success
    assert_equal(JSON.parse(response.body)['id'], @event.id)
  end

  test 'should not find existing event by title and content provider but no matching date' do
    post :check_exists, params: { format: :json, event: { title: @event.title,
                                                          url: 'whatever.com',
                                                          content_provider_id: @event.content_provider_id,
                                                          start: '2017-01-02' } }

    assert_response :success
    assert_equal '{}', response.body
  end

  test 'should find existing event by url' do
    post :check_exists, params: { format: :json, event: { title: 'whatever',
                                                          url: @event.url,
                                                          content_provider_id: @event.content_provider_id } }
    assert_response :success
    assert_equal(JSON.parse(response.body)['url'], @event.url)
    assert_equal(JSON.parse(response.body)['id'], @event.id)
  end

  test 'should find existing event by url without provider' do
    post :check_exists, params: { format: :json, event: { title: 'whatever', url: @event.url } }
    assert_response :success
    assert_equal(JSON.parse(response.body)['url'], @event.url)
    assert_equal(JSON.parse(response.body)['id'], @event.id)
  end

  test 'should find existing event by url and given content provider' do
    provider1 = content_providers(:iann)
    provider2 = content_providers(:two)

    e1 = provider1.events.create!(title: 'another event', url: @event.url, user: users(:regular_user))
    e2 = provider2.events.create!(title: 'a third event', url: @event.url, user: users(:regular_user))

    post :check_exists, params: { format: :json, event: { url: @event.url, content_provider_id: provider1.id } }
    assert_response :success
    assert_equal(JSON.parse(response.body)['id'], e1.id)

    post :check_exists, params: { format: :json, event: { url: @event.url, content_provider_id: provider2.id } }
    assert_response :success
    assert_equal(JSON.parse(response.body)['id'], e2.id)
  end

  test 'should return nothing when event does not exist' do
    post :check_exists, params: { format: :json, event: { url: 'http://no-such-site.com' } }
    assert_response :success
    assert_equal '{}', response.body
  end

  test 'should render properly when no url supplied' do
    post :check_exists, params: { format: :json, event: { url: nil } }
    assert_response :success
    assert_equal '{}', response.body
  end

  # TODO: SOLR tests will not run on TRAVIS. Explore stratergy for testing solr
  #       test 'should display filters on index' do
  #         get :index
  #         assert_select 'h4.nav-heading', :text => /Content provider/, :count => 0
  #         assert_select 'div.list-group-item', :count => Event.count
  #       end
  #
  #       test 'should return matching events' do
  #         get 'index', :format => :json, :q => 'training'
  #         assert_response :success
  #         assert response.body.size > 0
  #       end
  #
  #       test 'should return no matching events' do
  #         get 'index', :format => :json, :q => 'kdfsajfklasdjfljsdfljdsfjncvmn'
  #         assert_response :success
  #         assert_equal(response.body,'[]')
  #         end

  test 'should create new event through API' do
    scraper_role = Role.fetch('scraper_user')
    scraper_user = User.where(role_id: scraper_role.id).first
    event_title = 'horse'
    assert scraper_user
    assert_difference('Event.count') do
      post :create, params: {
        user_token: scraper_user.authentication_token,
        user_email: scraper_user.email,
        event: { title: event_title, url: 'http://horse.com', description: 'All about horses' }.merge(@mandatory_fields),
        format: 'json'
      }
    end
    assert_equal event_title, JSON.parse(response.body)['title']
  end

  test 'should not create new event without valid authentication token' do
    scraper_role = Role.fetch('scraper_user')
    scraper_user = User.where(role_id: scraper_role.id).first
    assert scraper_user

    assert_no_difference('Event.count') do
      post :create, params: {
        user_token: 'made up authentication token',
        user_email: scraper_user.email,
        event: {
          title: 'event_title',
          url: 'http://horse.com',
          description: 'All about horses'
        },
        format: 'json'
      }
    end
    assert_response 401
  end

  test 'should update existing event through API' do
    user = users(:scraper_user)
    event = events(:scraper_user_event)

    new_title = 'totally new title'
    assert_no_difference('Event.count') do
      patch :update, params: {
        user_token: user.authentication_token,
        user_email: user.email,
        event: {
          title: new_title,
          url: event.url,
          description: event.description
        },
        id: event.id,
        format: 'json'
      }
    end
    assert_not_equal event.title, JSON.parse(response.body)['title']
    assert_equal new_title, JSON.parse(response.body)['title']
  end

  test 'user can update their own event through the API' do
    user = users(:regular_user)
    event = user.events.first

    new_title = 'totally new title'
    assert_no_difference('Event.count') do
      patch :update, params: {
        user_token: user.authentication_token,
        user_email: user.email,
        event: {
          title: new_title,
          url: event.url,
          description: event.description
        },
        id: event.id,
        format: 'json'
      }
    end
    assert_response :success
  end

  test 'should add event to multiple collections' do
    sign_in @event.user
    collection1 = collections(:one)
    collection1_event_count = collection1.events.count
    collection2 = collections(:two)
    @event.collections = []
    @event.save!
    assert_difference('@event.collections.count', 2) do
      patch :update_collections, params: {
        id: @event.id,
        event: {
          collection_ids: [collection1.id, collection2.id]
        }
      }
    end
    assert_in_delta(collection1.events.count, collection1_event_count, 1)
  end

  test 'should remove event from collections' do
    sign_in @event.user
    collection1 = collections(:one)
    collection1_event_count = collection1.events.count
    collection2 = collections(:two)
    @event.collections << [collection1, collection2]
    @event.save

    assert_difference('@event.collections.count', -2) do
      patch :update_collections, params: {
        id: @event.id,
        event: {
          collection_ids: ['']
        }
      }
    end
    assert_in_delta(collection1.events.count, collection1_event_count, 1)
  end

  test 'should provide an ics file' do
    get :show, params: { format: :ics, id: @event.id }
    assert_response :success
    assert_equal 'text/calendar', @response.content_type

    cal_event = Icalendar::Calendar.parse(@response.body).first.events.first

    assert_equal @event.title, cal_event.summary
    assert_equal @event.description, cal_event.description
    assert !@event.all_day?, 'not an all day event'
    # Need to call .to_f, or Ruby thinks these two dates are not equal despite looking the same
    assert_equal @event.start.to_datetime.to_f, cal_event.dtstart.to_f
    assert_equal @event.end.to_datetime.to_f, cal_event.dtend.to_f
  end

  test 'calendar export should be set to utc dates' do
    # get the event
    local = events(:calendar_event)

    # get the icalendar content
    get :show, params: { format: :ics, id: local.id }
    assert_response :success
    assert_equal 'text/calendar', @response.content_type
    cal_event = Icalendar::Calendar.parse(@response.body).first.events.first

    # check the calendar event
    assert_equal local.title, cal_event.summary
    assert_equal local.start_utc, cal_event.dtstart
    assert_equal local.end_utc, cal_event.dtend
  end

  test 'should provide a csv file' do
    get :index, params: { format: :csv }
    assert_response :success
    assert_equal 'text/csv; charset=utf-8', @response.content_type
    csv_events = CSV.parse(@response.body)
    assert_equal csv_events.first, %w[Title Organizer Start End ContentProvider]
  end

  test 'should provide an RSS file' do
    get :index, params: { format: :rss }
    assert_response :success
    assert_equal 'application/rss+xml; charset=utf-8', @response.content_type
    rss_events = RSS::Parser.parse(@response.body)
    # there will be several events in the RSS feed, ordered as SOLR has output them
    # which varies during our tests.
    # find the one which will be first
    assert_equal Event.count, rss_events.items.count
    assert Event.friendly.find(rss_events.items.first.link.split('/').last.strip)

    event = rss_events.items.detect { |i| i.link == event_url(events(:event_with_external_resource)) }
    assert_not_nil event
    assert_equal 'External Resource Event', event.title
    description = event.description
    assert_includes description, '12 December 2016 @ 10:00 - 12:00'
    assert_includes description, 'this is my material'
    assert_includes description, 'AnOrganizer'
  end

  test 'should include parameters in RSS file' do
    get :index, params: { format: :rss, include_expired: true }
    assert_response :success
    assert_equal 'application/rss+xml; charset=utf-8', @response.content_type
    require 'rss'
    rss_events = RSS::Parser.parse(@response.body)
    assert_equal Event.count, rss_events.items.count

    assert_includes rss_events.channel.description, 'include_expired: true'
  end

  test 'should add external resource to event' do
    sign_in @event.user

    assert_difference('ExternalResource.count', 1) do
      patch :update, params: {
        id: @event,
        event: {
          title: 'New title',
          description: 'New description',
          url: 'http://new.url.com',
          external_resources_attributes: { '1' => { title: 'Cool link', url: 'https://tess.elixir-uk.org/', _destroy: '0' } }
        }
      }
    end

    assert_redirected_to event_path(assigns(:event))
    resource = assigns(:event).external_resources.last
    assert_equal 'Cool link', resource.title
    assert_equal 'https://tess.elixir-uk.org/', resource.url
  end

  test 'should remove external resource from event' do
    event = events(:event_with_external_resource)
    resource = event.external_resources.first
    sign_in event.user

    assert_difference('ExternalResource.count', -1) do
      patch :update, params: {
        id: event,
        event: {
          title: 'New title',
          description: 'New description',
          url: 'http://new.url.com',
          external_resources_attributes: { '0' => { id: resource.id, _destroy: '1' } }
        }
      }
    end

    assert_redirected_to event_path(assigns(:event))
    assert_equal 1, assigns(:event).external_resources.count
  end

  test 'should modify external resource from event' do
    event = events(:event_with_external_resource)
    resource = event.external_resources.first
    sign_in event.user

    assert_no_difference('ExternalResource.count') do
      patch :update, params: {
        id: event,
        event: {
          title: 'New title',
          description: 'New description',
          url: 'http://new.url.com',
          external_resources_attributes: { '1' => { id: resource.id, title: 'Cool link',
                                                    url: 'http://www.reddit.com', _destroy: '0' } }
        }
      }
    end

    assert_redirected_to event_path(assigns(:event))
    assert_equal 'Cool link', resource.reload.title
    assert_equal 'http://www.reddit.com', resource.url
  end

  test 'should sanitize description when creating event' do
    sign_in users(:regular_user)

    assert_difference('Event.count', 1) do
      post :create, params: {
        event: {
          description: '<b>hi</b><script>alert("hi!");</script>',
          title: 'Dirty Event',
          url: 'http://www.example.com/events/dirty'
        }.merge(@mandatory_fields)
      }
    end

    assert_redirected_to event_path(assigns(:event))
    assert_equal 'hi', assigns(:event).description
  end

  test 'can assign nodes by name' do
    sign_in users(:regular_user)

    assert_difference('Event.count') do
      post :create, params: {
        event: {
          title: @event.title,
          url: @event.url,
          description: @event.description,
          node_names: [nodes(:westeros).name, nodes(:good).name]
        }.merge(@mandatory_fields)
      }
    end

    assert_redirected_to event_path(assigns(:event))

    assert_includes assigns(:event).node_ids, nodes(:westeros).id
    assert_includes assigns(:event).node_ids, nodes(:good).id
  end

  test 'can lock fields' do
    sign_in @event.user
    assert_difference('FieldLock.count', 3) do
      patch :update, params: { id: @event, event: { title: 'hi', locked_fields: %w[title start end] } }
    end

    assert_redirected_to event_path(assigns(:event))
    assert_equal 3, assigns(:event).locked_fields.count
    assert assigns(:event).field_locked?(:title)
    assert assigns(:event).field_locked?(:start)
    assert assigns(:event).field_locked?(:end)
    refute assigns(:event).field_locked?(:description)
  end

  test 'scraper cannot overwrite locked fields' do
    user = users(:scraper_user)
    event = events(:scraper_user_event)
    event.locked_fields = [:title]
    event.save!

    assert_no_difference('Event.count') do
      patch :update, params: { user_token: user.authentication_token,
                               user_email: user.email,
                               event: {
                                 title: 'new title',
                                 url: event.url,
                                 description: 'new description'
                               },
                               id: event.id,
                               format: 'json' }
    end

    parsed_response = JSON.parse(response.body)
    assert_equal event.title, parsed_response['title'], 'Title should not have changed'
    assert_equal 'new description', parsed_response['description']
  end

  test 'normal user can overwrite locked fields' do
    @event.locked_fields = [:title]
    @event.save!

    sign_in @event.user
    patch :update, params: { id: @event, event: { title: 'new title' } }
    assert_redirected_to event_path(assigns(:event))

    assert_equal 'new title', assigns(:event).title
  end

  test 'should redirect to event URL' do
    assert_difference('WidgetLog.count', 1) do
      get :redirect, params: { id: @event }
    end

    assert_redirected_to @event.url
    assert_equal 1, @event.widget_logs.count

    log = @event.widget_logs.last

    assert_equal 'events#redirect', log.action
    assert_equal @event, log.resource
    assert_equal @event.url, log.data
  end

  test 'should count index results' do
    with_settings(solr_enabled: true) do
      events = Event.all

      Event.stub(:search_and_filter, MockSearch.new(events)) do
        get :count, params: { format: :json }
        output = JSON.parse(response.body)

        assert_response :success
        assert_equal events.count, output['count']
        assert_equal events_url, output['url']
      end
    end
  end

  test 'should count filtered results' do
    with_settings(solr_enabled: true) do
      events = Event.limit(3)

      Event.stub(:search_and_filter, MockSearch.new(events)) do
        get :count, params: { q: 'test', keywords: 'dolphins', blabla: 'booboo', format: :json }
        output = JSON.parse(response.body)

        assert_response :success
        assert_equal events.count, output['count']
        assert_equal events_url(q: 'test', keywords: 'dolphins'), output['url']
        assert_equal 'dolphins', output['params']['keywords']
      end
    end
  end

  test 'should not get report page for non-privileged users' do
    event = events(:event_with_report)
    sign_in users(:another_regular_user)

    get :report, params: { id: event }
    assert_response :forbidden
  end

  test 'should get report page for privileged user' do
    event = events(:event_with_report)
    sign_in event.user

    get :report, params: { id: event }
    assert_response :success
  end

  test 'should get report page for curator' do
    event = events(:event_with_report)
    sign_in users(:curator)

    get :report, params: { id: event }
    assert_response :success
  end

  test 'should get report page for admin' do
    event = events(:event_with_report)
    sign_in users(:admin)

    get :report, params: { id: event }
    assert_response :success
  end

  test 'should not update report for non-privileged users' do
    event = events(:event_with_report)
    sign_in users(:another_regular_user)

    patch :update_report, params: { id: event, event: { funding: 'test', attendee_count: 1337 } }

    assert_response :forbidden
    assert_not_equal 'test', assigns(:event).funding
    assert_not_equal 1337, assigns(:event).attendee_count
  end

  test 'should update report for privileged users' do
    event = events(:event_with_report)
    sign_in event.user

    patch :update_report, params: { id: event, event: { funding: 'test', attendee_count: 1337 } }

    assert_redirected_to event_path(assigns(:event), anchor: 'report')
    assert_equal 'test', assigns(:event).funding
    assert_equal 1337, assigns(:event).attendee_count
  end

  test 'should update report for curator' do
    event = events(:event_with_report)
    sign_in users(:curator)

    patch :update_report, params: { id: event, event: { funding: 'test', attendee_count: 1337 } }

    assert_redirected_to event_path(assigns(:event), anchor: 'report')
    assert_equal 'test', assigns(:event).funding
    assert_equal 1337, assigns(:event).attendee_count
  end

  test 'should update report for admin' do
    event = events(:event_with_report)
    sign_in users(:admin)

    patch :update_report, params: { id: event, event: { funding: 'test', attendee_count: 1337 } }

    assert_redirected_to event_path(assigns(:event), anchor: 'report')
    assert_equal 'test', assigns(:event).funding
    assert_equal 1337, assigns(:event).attendee_count
  end

  test 'should not show report to non-privileged users' do
    event = events(:event_with_report)
    sign_in users(:another_regular_user)

    get :show, params: { id: event }
    assert_select '#report', count: 0
  end

  test 'should show report to privileged users' do
    event = events(:event_with_report)
    sign_in event.user

    get :show, params: { id: event }
    assert_select '#report', count: 1
  end

  test 'should show report to curator' do
    event = events(:event_with_report)
    sign_in users(:curator)

    get :show, params: { id: event }
    assert_select '#report', count: 1
  end

  test 'should show report to admin' do
    event = events(:event_with_report)
    sign_in users(:admin)

    get :show, params: { id: event }
    assert_select '#report', count: 1
  end

  test 'should only show report fields in JSON to privileged users' do
    hidden_report_event = events(:event_with_report)
    visible_report_event = events(:another_event_with_report)
    sign_in users(:another_regular_user)

    get :show, params: { id: hidden_report_event, format: :json }
    refute JSON.parse(response.body).key?('funding')
    assert_valid_legacy_json_response

    get :show, params: { id: visible_report_event, format: :json }
    assert_equal visible_report_event.funding, JSON.parse(response.body)['funding']
    assert_valid_legacy_json_response
  end

  test 'should only show report fields in JSON index to privileged users' do
    hidden_report_event = events(:event_with_report)
    visible_report_event = events(:another_event_with_report)
    sign_in users(:another_regular_user)

    get :index, format: :json
    assert_valid_legacy_json_response
    hidden_report_event_json = JSON.parse(response.body).detect { |e| e['id'] == hidden_report_event.id }
    visible_report_event_json = JSON.parse(response.body).detect { |e| e['id'] == visible_report_event.id }
    refute hidden_report_event_json.key?('funding')
    assert_equal visible_report_event.funding, visible_report_event_json['funding']
  end

  test 'should only show report fields in JSON-API to privileged users' do
    hidden_report_event = events(:event_with_report)
    visible_report_event = events(:another_event_with_report)
    sign_in users(:another_regular_user)

    get :show, params: { id: hidden_report_event, format: :json_api }
    assert_valid_json_api_response
    refute JSON.parse(response.body)['data']['attributes'].key?('report')

    get :show, params: { id: visible_report_event, format: :json_api }
    assert_valid_json_api_response
    assert_equal visible_report_event.funding, JSON.parse(response.body)['data']['attributes']['report']['funding']
  end

  test 'should only show report fields in JSON-API index to privileged users' do
    hidden_report_event = events(:event_with_report)
    visible_report_event = events(:another_event_with_report)
    sign_in users(:another_regular_user)

    get :index, format: :json_api
    assert_valid_json_api_response
    hidden_report_event_json = JSON.parse(response.body)['data'].detect { |e| e['id'].to_i == hidden_report_event.id }
    visible_report_event_json = JSON.parse(response.body)['data'].detect { |e| e['id'].to_i == visible_report_event.id }
    refute hidden_report_event_json['attributes'].key?('report')
    assert_equal visible_report_event.funding, visible_report_event_json['attributes']['report']['funding']
  end

  test 'should approve topic for curator' do
    sign_in users(:curator)

    assert_empty @event.scientific_topic_names

    suggestion = @event.build_edit_suggestion
    suggestion.scientific_topic_uris = ['http://edamontology.org/topic_0622']
    suggestion.save!

    assert_difference(-> { suggestion.scientific_topic_links.count }, -1) do
      assert_difference(-> { @event.scientific_topic_links.count }, 1) do
        assert_difference('EditSuggestion.count', -1) do
          post :add_term, params: { id: @event.id, field: 'scientific_topics', uri: 'http://edamontology.org/topic_0622' }
        end
      end
    end

    assert_response :success

    assert_equal ['Genomics'], @event.reload.scientific_topic_names
    assert_nil @event.reload.edit_suggestion
  end

  test 'should reject topic for curator' do
    sign_in users(:curator)

    assert_empty @event.scientific_topic_names

    suggestion = @event.build_edit_suggestion
    suggestion.scientific_topic_uris = ['http://edamontology.org/topic_0622']
    suggestion.save!

    assert_difference('EditSuggestion.count', -1) do
      post :reject_term, params: { id: @event.id, field: 'scientific_topics', uri: 'http://edamontology.org/topic_0622' }
    end

    assert_response :success

    assert_empty @event.reload.scientific_topic_names
    assert_nil @event.reload.edit_suggestion
  end

  test 'should not approve topic for unprivileged user' do
    sign_in users(:another_regular_user)

    assert_empty @event.scientific_topic_names

    suggestion = @event.build_edit_suggestion
    suggestion.scientific_topic_uris = ['http://edamontology.org/topic_0622']
    suggestion.save!

    assert_no_difference('EditSuggestion.count') do
      post :add_term, params: { id: @event.id, field: 'scientific_topics', uri: 'http://edamontology.org/topic_0622' }
    end

    assert_response :forbidden

    assert_empty @event.reload.scientific_topic_names
    assert_equal ['Genomics'], @event.reload.edit_suggestion.scientific_topic_names
  end

  test 'should not reject topic for unprivileged user' do
    sign_in users(:another_regular_user)

    assert_empty @event.scientific_topic_names

    suggestion = @event.build_edit_suggestion
    suggestion.scientific_topic_uris = ['http://edamontology.org/topic_0622']
    suggestion.save!

    assert_no_difference('EditSuggestion.count') do
      post :reject_term, params: { id: @event.id, field: 'scientific_topics', uri: 'http://edamontology.org/topic_0622' }
    end

    assert_response :forbidden

    assert_empty @event.reload.scientific_topic_names
    assert_equal ['Genomics'], @event.reload.edit_suggestion.scientific_topic_names
  end

  test 'should approve data for curator' do
    sign_in users(:curator)
    event = events(:two)

    assert_nil event.latitude
    assert_nil event.longitude

    suggestion = event.build_edit_suggestion
    suggestion.data_fields = { 'geographic_coordinates' => [25, 25] }
    suggestion.save!

    assert_difference('EditSuggestion.count', -1) do
      post :add_data, params: { id: event.id, data_field: 'geographic_coordinates' }
    end

    assert_response :success

    event.reload

    assert_equal 25, event.latitude
    assert_equal 25, event.longitude
  end

  test 'should not approve data for unprivileged user' do
    sign_in users(:another_regular_user)
    event = events(:two)

    assert_nil event.latitude
    assert_nil event.longitude

    suggestion = event.build_edit_suggestion
    suggestion.data_fields = { 'geographic_coordinates' => [25, 25] }
    suggestion.save!

    assert_no_difference('EditSuggestion.count') do
      post :add_data, params: { id: event.id, data_field: 'geographic_coordinates' }
    end

    assert_response :forbidden

    event.reload

    assert_nil event.latitude
    assert_nil event.longitude
  end

  test 'should reject data for curator' do
    sign_in users(:curator)
    event = events(:two)

    assert_nil event.latitude
    assert_nil event.longitude

    suggestion = event.build_edit_suggestion
    suggestion.data_fields = { 'geographic_coordinates' => [25, 25] }
    suggestion.save!

    assert_difference('EditSuggestion.count', -1) do
      post :reject_data, params: { id: event.id, data_field: 'geographic_coordinates' }
    end

    assert_response :success

    event.reload

    assert_nil event.latitude
    assert_nil event.longitude
  end

  test 'should not reject data for unprivileged user' do
    sign_in users(:another_regular_user)
    event = events(:two)

    assert_nil event.latitude
    assert_nil event.longitude

    suggestion = event.build_edit_suggestion
    suggestion.data_fields = { 'geographic_coordinates' => [25, 25] }
    suggestion.save!

    assert_no_difference('EditSuggestion.count') do
      post :reject_data, params: { id: event.id, data_field: 'geographic_coordinates' }
    end

    assert_response :forbidden

    event.reload

    assert_nil event.latitude
    assert_nil event.longitude
  end

  test 'should show user ban info to admin' do
    event = events(:shadowbanned_event)
    sign_in users(:admin)

    get :show, params: { id: event }
    assert_response :success
    assert_select '.ban-info', count: 1
  end

  test 'should not show user ban info to non-admin' do
    event = events(:shadowbanned_event)
    sign_in users(:shadowbanned_user)

    get :show, params: { id: event }
    assert_response :success
    assert_select '.ban-info', count: 0
  end

  test 'should get event with edit suggestion' do
    suggestion = @event.build_edit_suggestion
    suggestion.scientific_topic_uris = ['http://edamontology.org/topic_0622']
    suggestion.save!

    get :show, params: { id: @event }
    assert_response :success
  end

  test 'should show identifiers dot org button for event' do
    get :show, params: { id: @event }

    assert_response :success
    assert_select '.identifiers-button'
    assert_select '#identifiers-link[value=?]', "http://example.com/identifiers/banana:e#{@event.id}"
  end

  test 'should not show identifiers dot org button if disabled' do
    with_settings(identifiers_prefix: nil) do
      get :show, params: { id: @event }

      assert_response :success
      assert_select '.identifiers-button', count: 0
    end
  end

  test 'Filters facet parameters correctly' do
    get :index, params: { q: 'search',
                          id: 'what am i doing',
                          keywords: 'foo',
                          fish: 'not a valid parameter',
                          country: %w[France Germany] }

    # Facet params
    assert_equal 2, assigns(:facet_params).keys.length
    assert_equal 'foo', assigns(:facet_params)['keywords']
    assert_equal %w[France Germany], assigns(:facet_params)['country']
    assert_nil assigns(:facet_params)['fish']
    assert_nil assigns(:facet_params)['id']

    # Search params
    assert_equal 'search', assigns(:search_params)
  end

  test 'should disable map tab if only showing online events' do
    get :index
    assert_response :success
    assert_select '#content .nav' do
      assert_select 'li.disabled a[href=?]', '#map', count: 0
      assert_select 'li a[href=?]', '#map', count: 1
    end

    get :index, params: { online: 'true' }
    assert_response :success
    assert_select '#content .nav' do
      assert_select 'li.disabled a[href=?]', '#map', count: 1
    end
  end

  test 'should hide map tab if disabled' do
    assert Rails.application.config.secrets.google_maps_api_key.present?
    assert TeSS::Config.map_enabled

    get :index
    assert_response :success
    assert_select '#content .nav' do
      assert_select 'li a[href=?]', '#map', count: 1
    end

    with_settings(feature: { disabled: ['events_map'] }) do
      assert Rails.application.config.secrets.google_maps_api_key.present?
      refute TeSS::Config.map_enabled

      get :index
      assert_response :success
      assert_select '#content .nav' do
        assert_select 'li a[href=?]', '#map', count: 0
      end
    end
  end

  test 'should use open street map if no API key' do
    Rails.application.config.secrets.stub(:google_maps_api_key, nil) do
      refute Rails.application.config.secrets.google_maps_api_key.present?
      refute TeSS::Config.use_google_maps
      assert_equal 'open-street-map', TeSS::Config.map_provider

      get :index
      assert_response :success
      assert_select '#content .nav' do
        assert_select 'li a[href=?]', '#map', count: 1
      end
      assert_select 'div[data-provider="open-street-map"]', count: 1
      assert_no_match(/maps\.googleapis\.com/, response.body)
    end
  end

  test 'should use google map if API key given' do
    assert Rails.application.config.secrets.google_maps_api_key.present?
    assert TeSS::Config.use_google_maps
    assert_equal 'google', TeSS::Config.map_provider

    get :index
    assert_response :success
    assert_select '#content .nav' do
      assert_select 'li a[href=?]', '#map', count: 1
    end
    assert_select 'div[data-provider="google"]', count: 1
    assert_match(/maps\.googleapis\.com/, response.body)
  end

  test 'should clone event' do
    sign_in @event.user
    get :clone, params: { id: @event }
    assert_response :success
    assert_nil assigns(:event).url
    assert_nil assigns(:event).id
    assert_equal @event.title, assigns(:event).title
    assert_select '#event_title[value=?]', @event.title
  end

  test 'should not clone event if no permission' do
    sign_in users(:another_regular_user)
    get :clone, params: { id: @event }
    assert_response :forbidden
  end

  test 'should show map if location data' do
    get :show, params: { id: events(:one) }
    assert_response :success
    assert_select '#map'
  end

  test 'should not show map if no location data' do
    get :show, params: { id: events(:portal_event) }
    assert_response :success
    assert_select '#map', count: 0
  end

  test 'should not show map if disabled' do
    with_settings(feature: { disabled: ['events_map'] }) do
      assert Rails.application.config.secrets.google_maps_api_key.present?
      refute TeSS::Config.map_enabled
      refute TeSS::Config.use_google_maps
      get :show, params: { id: events(:one) }
      assert_response :success
      assert_select '#map', count: 0
    end
  end

  test 'should not show address finder if disabled' do
    sign_in users(:regular_user)
    assert TeSS::Config.map_enabled
    assert TeSS::Config.address_finder_enabled
    get :new
    assert_response :success
    assert_select '#event-map-form', count: 1
    with_settings(feature: { disabled: ['address_finder'] }) do
      assert TeSS::Config.map_enabled
      refute TeSS::Config.address_finder_enabled
      get :new
      assert_response :success
      assert_select '#event-map-form', count: 0
    end
  end

  test 'should show calendar events' do
    (1..200).each do |i|
      Event.create(title: "hi#{i}", url: "http://google.com#hi#{i}",
                   user: User.first, content_provider: ContentProvider.first, timezone: 'UTC',
                   start: Time.now.beginning_of_month.noon - 8.days, end: Time.now.noon - 1.day + 7.hours, city: 'Tilburg', country: 'Netherlands')
    end
    Event.create(title: 'relevant_event', url: 'http://google.com#relevant',
                 user: User.first, content_provider: ContentProvider.first, timezone: 'UTC',
                 start: Time.now.noon, end: Time.now.noon + 7.hours, city: 'Tilburg', country: 'Netherlands')
    Event.create(title: 'long relevant_event', url: 'http://google.com#long_relevant',
                 user: User.first, content_provider: ContentProvider.first, timezone: 'UTC',
                 start: Time.now.noon, end: Time.now.noon + 1.month + 7.hours, city: 'Tilburg', country: 'Netherlands')
    sign_in users(:another_regular_user)
    get :index
    assert_select 'li a[href=?]', '#calendar', count: 1
    get :calendar
    @response.body.include? 'relevant_event'
    @response.body.include? 'long_relevant_event'
  end

  test 'should preview event' do
    sign_in users(:regular_user)

    assert_no_difference('Event.count') do
      assert_no_difference('ExternalResource.count') do
        post :preview, params: { event: { title: 'Potential event',
                                          url: 'https://someevent.com',
                                          external_resources_attributes: [
                                            { title: 'A tool perhaps', url: 'https://bio.tools/some_tool' }
                                          ] } }

        assert_response :success
        assert_select 'h2', text: 'Potential event'
        assert_select '.external-resources-box a[href=?]', 'https://bio.tools/some_tool'
      end
    end
  end

  test 'should not preview invalid event' do
    sign_in users(:regular_user)

    assert_no_difference('Event.count') do
      assert_no_difference('ExternalResource.count') do
        post :preview, params: { event: { title: 'Missing URL' } }

        assert_response :unprocessable_entity
      end
    end
  end

  test 'should show logo in events' do
    with_settings({ site: { show_provider_logo_in_event: true } }) do
      get :index
      assert_response :success
      assert_select '.small-avatar'
    end
  end

  test 'should not show logo in events' do
    with_settings({ site: { show_provider_logo_in_event: false } }) do
      get :index
      assert_response :success
      assert_select '.small-avatar', count: 0
    end
  end

  test 'should show unverified users event to themselves' do
    sign_in users(:unverified_user)
    event = users(:unverified_user).events.create!(title: 'Hello', description: 'World',
                                                   url: 'https://example.com/event')

    get :show, params: { id: event }

    assert_response :success
    assert_select '.unverified-notice',
                  text: 'This event will not be publicly visible until your registration has been approved by an administrator.'
  end

  test 'should show unverified users event to admin' do
    event = users(:unverified_user).events.create!(title: 'Hello', description: 'World',
                                                   url: 'https://eexample.com/event')
    sign_in users(:admin)

    get :show, params: { id: event }

    assert_response :success
    assert_select '.unverified-notice',
                  text: 'This event will not be publicly visible until your registration has been approved by an administrator.'
  end

  test 'should not show unverified users event anon user' do
    event = users(:unverified_user).events.create!(title: 'Hello', description: 'World',
                                                   url: 'https://example.com/event')

    get :show, params: { id: event }
    assert_response :forbidden
  end

  test 'should create event without language specified' do
    sign_in users(:regular_user)
    assert_difference('Event.count', 1) do
      post :create, params: { event: { description: @event.description, title: @event.title, url: @event.url,
                                       language: '' } }
    end
    assert_redirected_to event_path(assigns(:event))
    refute assigns(:event).language.present?
  end

  test 'should display language of instruction' do
    get :show, params: { id: events(:one) }
    assert_response :success
    assert_select 'strong', text: 'Language of instruction:'
  end

  test 'should not display language of instruction if not specified' do
    event = users(:regular_user).events.create!(title: 'No language', url: 'https://example.com/nolang', language: '')

    get :show, params: { id: event }
    assert_response :success
    assert_select 'strong', text: 'Language of instruction:', count: 0
  end
end
