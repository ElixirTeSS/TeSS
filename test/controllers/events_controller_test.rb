require 'test_helper'
require 'icalendar'

class EventsControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  setup do
    @event = events(:one)
    u = users(:regular_user)
    @event.user = u
    @event.save!
    @updated_event = {
        title: 'New title',
        short_description: 'New description'
    }
  end

  #Tests
  # INDEX, NEW, EDIT, CREATE, SHOW, BREADCRUMBS, TABS, API CHECKS

  #INDEX TESTS
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:events)
  end

  #NEW TESTS
  test 'should get new' do
    sign_in users(:regular_user)
    get :new
    assert_response :success
  end

  test 'should get new page for logged in users only' do
    #Redirect to login if not logged in
    get :new
    assert_response :redirect
    sign_in users(:regular_user)
    #Success for everyone else
    get :new
    assert_response :success
    sign_in users(:admin)
    get :new
    assert_response :success
  end

  #EDIT TESTS
  test 'should not get edit page for not logged in users' do
    #Not logged in = Redirect to login
    get :edit, id: @event
    assert_redirected_to new_user_session_path
  end

    #logged in but insufficient permissions = ERROR
  test 'should get edit for event owner' do
    sign_in @event.user
    get :edit, id: @event
    assert_response :success
  end

  test 'should get edit for admin' do
    #Owner of event logged in = SUCCESS
    sign_in users(:admin)
    get :edit, id: @event
    assert_response :success
  end

  test 'should get edit for curator' do
    sign_in users(:curator)
    get :edit, id: @event
    assert_response :success
  end

  test 'should not get edit page for non-owner user' do
    #Administrator = SUCCESS
    sign_in users(:another_regular_user)
    get :edit, id: @event
    assert :forbidden
  end

  #CREATE TEST
  test 'should create event for user' do
    sign_in users(:regular_user)
    assert_difference('Event.count') do
      post :create, event: {description: @event.description, title: @event.title, url: @event.url }
    end
    assert_redirected_to event_path(assigns(:event))
  end

  test 'should create event for admin' do
    sign_in users(:admin)
    assert_difference('Event.count') do
      post :create, event: {description: @event.description, title: @event.title, url: @event.url }
    end
    assert_redirected_to event_path(assigns(:event))
  end

  test 'should not create event for non-logged in user' do
    assert_no_difference('Event.count') do
      post :create, event: {description: @event.description, title: @event.title, url: @event.url }
    end
    assert_redirected_to new_user_session_path
  end

  #SHOW TEST
  test 'should show event' do
    get :show, id: @event
    assert_response :success
    assert assigns(:event)
  end


  #UPDATE TEST
  test 'should update event' do
    sign_in @event.user
    # patch :update, id: @event, event: { doi: @event.doi,  remote_created_date: @event.remote_created_date,  remote_updated_date: @event.remote_updated_date, short_description: @event.short_description, title: @event.title, url: @event.url }
    patch :update, id: @event, event: @updated_event
    assert_redirected_to event_path(assigns(:event))
  end

  test 'should update event if curator' do
    sign_in users(:curator)
    assert_not_equal @event.user, users(:curator)
    patch :update, id: @event, event: @updated_event
    assert_redirected_to event_path(assigns(:event))
  end

  test 'should not update event if not owner or curator etc.' do
    sign_in users(:collaborative_user)
    assert_not_equal @event.user, users(:collaborative_user)
    patch :update, id: @event, event: @updated_event
    assert_response :forbidden
  end

  #DESTROY TEST
  test 'should destroy event owned by user' do
    sign_in @event.user
    assert_difference('Event.count', -1) do
      delete :destroy, id: @event
    end
    assert_redirected_to events_path
  end

  test 'should destroy event when administrator' do
    sign_in users(:admin)
    assert_difference('Event.count', -1) do
      delete :destroy, id: @event
    end
    assert_redirected_to events_path
  end

  test 'should destroy event when curator' do
    sign_in users(:curator)
    assert_difference('Event.count', -1) do
      delete :destroy, id: @event
    end
    assert_redirected_to events_path
  end

  test 'should not destroy event not owned by user' do
    sign_in users(:another_regular_user)
    assert_no_difference('Event.count') do
      delete :destroy, id: @event
    end
    assert_response :forbidden
  end


  #CONTENT TESTS
  #BREADCRUMBS
  test 'breadcrumbs for events index' do
    get :index
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li[class=active]', :text => /Events/, :count => 1
    end
  end

  test 'breadcrumbs for showing event' do
    get :show, :id => @event
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Events/, :count => 1 do
        assert_select 'a[href=?]', events_url, :count => 1
      end
      assert_select 'li[class=active]', :text => /#{@event.title}/, :count => 1
    end
  end

  test 'breadcrumbs for editing event' do
    sign_in users(:admin)
    get :edit, id: @event
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Events/, :count => 1 do
        assert_select 'a[href=?]', events_url, :count => 1
      end
      assert_select 'li', :text => /#{@event.title}/, :count => 1 do
        assert_select 'a[href=?]', event_url(@event), :count => 1
      end
      assert_select 'li[class=active]', :text => /Edit/, :count => 1
    end
  end

  test 'breadcrumbs for creating new event' do
    sign_in users(:regular_user)
    get :new
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Events/, :count => 1 do
        assert_select 'a[href=?]', events_url, :count => 1
      end
      assert_select 'li[class=active]', :text => /New/, :count => 1
    end
  end

  #OTHER CONTENT
  test 'event has correct tabs' do
    get :show, :id => @event

    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li' do
        assert_select 'a[data-toggle="tab"]', :count => 2 # Event, Activity
      end
      assert_select 'li.disabled', :count => 1 # Packages
    end
  end

  test 'event has correct layout' do
    get :show, :id => @event
    assert_response :success
    assert_select 'h2', :text => @event.title #Has Title
    assert_select 'a.h5[href=?]', @event.url #Has plain written URL
    #assert_select 'a.btn-info[href=?]', events_path, :count => 1 #Back button
    assert_select 'a.btn-success', :text => "View event", :count => 1 do
      assert_select 'a[href=?]', @event.url, :count => 1 #View event button
    end
    #Should not show when not logged in
    assert_select 'a.btn-primary[href=?]', edit_event_path(@event), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', event_path(@event), :count => 0 #No Edit
  end

  test 'do not show action buttons when not owner or admin' do
    sign_in users(:another_regular_user)
    get :show, :id => @event
    assert_select 'a.btn-primary[href=?]', edit_event_path(@event), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', event_path(@event), :count => 0 #No Edit
  end

  test 'should show action buttons when owner' do
    sign_in @event.user
    get :show, :id => @event
    assert_select 'a.btn-primary[href=?]', edit_event_path(@event), :count => 1
    assert_select 'a.btn-danger[href=?]', event_path(@event), :text => 'Delete', :count => 1
  end

  test 'should show action buttons when admin' do
    sign_in users(:admin)
    get :show, :id => @event
    assert_select 'a.btn-primary[href=?]', edit_event_path(@event), :count => 1
    assert_select 'a.btn-danger[href=?]', event_path(@event), :text => 'Delete', :count => 1
  end

  #API Actions


  test 'should find existing event by url' do
    post 'check_exists', :format => :json,  :url => @event.url
    assert_response :success
    assert_equal(JSON.parse(response.body)['title'], @event.title)
  end

  test 'should return nothing when event does not exist' do
    post 'check_exists', :format => :json,  :url => 'http://no-such-site.com'
    assert_response :success
    assert_equal(response.body, '')
  end

  test 'should render properly when no url supplied' do
    post 'check_exists', :format => :json,  :url => nil
    assert_response :success
    assert_equal(response.body, '')
  end


  # TODO: SOLR tests will not run on TRAVIS. Explore stratergy for testing solr
=begin
      test 'should display filters on index' do
        get :index
        assert_select 'h4.nav-heading', :text => /Content provider/, :count => 0
        assert_select 'div.list-group-item', :count => Event.count
      end

      test 'should return matching events' do
        get 'index', :format => :json, :q => 'training'
        assert_response :success
        assert response.body.size > 0
      end

      test 'should return no matching events' do
        get 'index', :format => :json, :q => 'kdfsajfklasdjfljsdfljdsfjncvmn'
        assert_response :success
        assert_equal(response.body,'[]')
        end
=end

  test 'should create new event through API' do
    scraper_role = Role.fetch('api_user')
    scraper_user = User.where(:role_id => scraper_role.id).first
    event_title = 'horse'
    assert scraper_user
    assert_difference('Event.count') do
      post 'create', {user_token: scraper_user.authentication_token,
                      user_email: scraper_user.email,
                      event: {
                          title: event_title,
                          url: 'http://horse.com',
                          short_description: 'All about horses'
                      },
                      :format => 'json'}
    end
    assert_equal event_title, JSON.parse(response.body)['title']
  end

  test 'should not create new event without valid authentication token' do
    scraper_role = Role.fetch('api_user')
    scraper_user = User.where(:role_id => scraper_role.id).first
    assert scraper_user

    assert_no_difference('Event.count') do
      post 'create', {user_token: 'made up authentication token',
                      user_email: scraper_user.email,
                      event: {
                          title: 'event_title',
                          url: 'http://horse.com',
                          description: 'All about horses'
                      },
                      :format => 'json'}
    end
    assert_response 401
  end


  test 'should update existing material through API' do
    user = users(:scraper_user)
    event = events(:scraper_user_event)

    new_title = "totally new title"
    assert_no_difference('Material.count') do
      post 'update', {user_token: user.authentication_token,
                      user_email: user.email,
                      event: {
                          title: new_title,
                          url: event.url,
                          description: event.description
                      },
                      :id => event.id,
                      :format => 'json'}
    end
    assert_not_equal event.title, JSON.parse(response.body)['title']
    assert_equal new_title, JSON.parse(response.body)['title']
  end

  test 'user can update their own event through the API' do
    user = users(:regular_user)
    event = user.events.first

    new_title = "totally new title"
    assert_no_difference('Event.count') do
      post 'update', {user_token: user.authentication_token,
                      user_email: user.email,
                      event: {
                          title: new_title,
                          url: event.url,
                          description: event.description
                      },
                      :id => event.id,
                      :format => 'json'}
    end
    assert_response :success
  end

  test 'should add material to multiple packages' do
    sign_in @event.user
    package1 = packages(:one)
    package1_event_count = package1.events.count
    package2 = packages(:two)
    @event.packages = []
    @event.save!
    assert_difference('@event.packages.count', 2) do
      post 'update_packages', { id: @event.id,
                                event: {
                                    package_ids: [package1.id, package2.id]
                                }
                            }
    end
    assert_in_delta(package1.events.count, package1_event_count, 1)
  end

  test 'should remove material from packages' do
    sign_in @event.user
    package1 = packages(:one)
    package1_event_count = package1.events.count
    package2 = packages(:two)
    @event.packages << [package1, package2]
    @event.save

    assert_difference('@event.packages.count', -2) do
      post 'update_packages', { id: @event.id,
                                event: {
                                    package_ids: ['']
                                }
                            }
    end
    assert_in_delta(package1.events.count, package1_event_count, 1)
  end

  test 'should provide an ics file' do
    get :show, format: :ics, id: @event.id

    assert_response :success
    assert_equal 'text/calendar', @response.content_type

    cal_event = Icalendar::Calendar.parse(@response.body).first.events.first

    assert_equal @event.title, cal_event.summary
    assert_equal @event.description, cal_event.description
    # Need to call .to_s, or Ruby thinks these two dates are not equal despite looking the same
    assert_equal @event.start.to_date.to_s, cal_event.dtstart.to_s
    assert_equal @event.end.to_date.to_s, cal_event.dtend.to_s
  end

  test 'should provide a csv file' do
    get :index, format: :csv

    assert_response :success
    assert_equal 'text/csv', @response.content_type
    csv_events = CSV.parse(@response.body)
    assert_equal csv_events.first, ["Title", "Organizer", "Start", "End", "ContentProvider"]

  end

  test 'should add external resource to event' do
    sign_in @event.user

    assert_difference('ExternalResource.count', 1) do
      patch :update, id: @event, event: {
          title: 'New title',
          description: 'New description',
          url: 'http://new.url.com',
          external_resources_attributes: { "1" => { title: 'Cool link', url: 'https://tess.elixir-uk.org/', _destroy: '0' } }
      }
    end

    assert_redirected_to event_path(assigns(:event))
    resource = assigns(:event).external_resources.first
    assert_equal 'Cool link', resource.title
    assert_equal 'https://tess.elixir-uk.org/', resource.url
  end

  test 'should remove external resource from event' do
    event = events(:event_with_external_resource)
    resource = event.external_resources.first
    sign_in event.user

    assert_difference('ExternalResource.count', -1) do
      patch :update, id: event, event: {
          title: 'New title',
          description: 'New description',
          url: 'http://new.url.com',
          external_resources_attributes: { "0" => { id: resource.id, _destroy: '1' } }
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
      patch :update, id: event, event: {
          title: 'New title',
          description: 'New description',
          url: 'http://new.url.com',
          external_resources_attributes: { "1" => { id: resource.id, title: 'Cool link',
                                                    url: 'http://www.reddit.com', _destroy: '0' } }
      }
    end

    assert_redirected_to event_path(assigns(:event))
    resource = assigns(:event).external_resources.first
    assert_equal 'Cool link', resource.title
    assert_equal 'http://www.reddit.com', resource.url
  end

  test 'should sanitize description when creating event' do
    sign_in users(:regular_user)

    assert_difference('Event.count', 1) do
      post :create, event: { description: '<b>hi</b><script>alert("hi!");</script>',
                             title: 'Dirty Event',
                             url: 'http://www.example.com/events/dirty' }
    end

    assert_redirected_to event_path(assigns(:event))
    assert_equal 'hi', assigns(:event).description
  end

  test 'can assign nodes by name' do
    sign_in users(:regular_user)

    assert_difference('Event.count') do
      post :create, event: { title: @event.title,
                             url: @event.url,
                             node_names: [nodes(:westeros).name, nodes(:good).name]
      }
    end

    assert_redirected_to event_path(assigns(:event))

    assert_includes assigns(:event).node_ids, nodes(:westeros).id
    assert_includes assigns(:event).node_ids, nodes(:good).id
  end

end
