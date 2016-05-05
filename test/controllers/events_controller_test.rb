require 'test_helper'

class EventsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  setup do
    @event = events(:one)
  end

require 'test_helper'

class EventsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

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
        assert_select 'a[data-toggle="tab"]', :count => 2
      end
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

  test 'should not show action buttons when owner' do
    sign_in @event.user
    get :show, :id => @event
    assert_select 'a.btn-primary[href=?]', edit_event_path(@event), :count => 0
    assert_select 'a.btn-danger[href=?]', event_path(@event), :text => 'Delete', :count => 0
  end

  test 'should not show action buttons when admin' do
    sign_in users(:admin)
    get :show, :id => @event
    assert_select 'a.btn-primary[href=?]', edit_event_path(@event), :count => 0
    assert_select 'a.btn-danger[href=?]', event_path(@event), :text => 'Delete', :count => 0
  end

  #API Actions
  test 'should find existing event by title' do
    post 'check_exists', :format => :json,  :title => @event.title
    assert_response :success
    assert_equal(JSON.parse(response.body)['title'], @event.title)
  end

  test 'should find existing event by url' do
    post 'check_exists', :format => :json,  :url => @event.url
    assert_response :success
    assert_equal(JSON.parse(response.body)['title'], @event.title)
  end

  test 'should return nothing when event does not exist' do
    post 'check_exists', :format => :json,  :title => 'This title should not exist'
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
