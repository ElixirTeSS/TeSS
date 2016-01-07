require 'test_helper'

class EventsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  setup do
    @event = events(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:events)
  end

  test "should get new" do
    sign_in users(:regular_user)
    get :new
    assert_response :success
  end

  test "should create event" do
    sign_in users(:regular_user)
    assert_difference('Event.count') do
      post :create, event: { category: @event.category, city: @event.city, country: @event.country, county: @event.county, description: @event.description, end: @event.end, field: @event.field, id: @event.id, latitude: @event.latitude, link: @event.link, longitude: @event.longitude, postcode: @event.postcode, provider: @event.provider, sponsor: @event.sponsor, start: @event.start, subtitle: @event.subtitle, title: @event.title, venue: @event.venue }
    end

    assert_redirected_to event_path(assigns(:event))
  end

  test "should show event" do
    get :show, id: @event
    assert_response :success
  end

  test "should get edit" do
    sign_in users(:regular_user)
    get :edit, id: @event
    assert_response :success
  end

  test "should update event" do
    sign_in users(:regular_user)
    patch :update, id: @event, event: { category: @event.category, city: @event.city, country: @event.country, county: @event.county, description: @event.description, end: @event.end, field: @event.field, id: @event.id, latitude: @event.latitude, link: @event.link, longitude: @event.longitude, postcode: @event.postcode, provider: @event.provider, sponsor: @event.sponsor, start: @event.start, subtitle: @event.subtitle, title: @event.title, venue: @event.venue }
    assert_redirected_to event_path(assigns(:event))
  end

  test "should destroy event" do
    sign_in users(:regular_user)
    assert_difference('Event.count', -1) do
      delete :destroy, id: @event
    end
    assert_redirected_to events_path
  end

  test "should find event by title" do
    post 'check_exists', :format => :json,  :title => @event.title
    assert_response :success
    assert_equal(JSON.parse(response.body)['title'], @event.title)
  end

  test "should return nothing when event does't exist" do
    post 'check_exists', :format => :json,  :title => 'This title should not exist'
    assert_response :success
    assert_equal(response.body, "")
  end

end
