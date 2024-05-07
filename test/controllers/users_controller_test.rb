require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    mock_images
    mock_orcids
    @user = users(:regular_user)
    @admin = users(:admin)
  end

  test 'should get index page for everyone' do
    get :index
    assert_response :success
    sign_in users(:regular_user)
    assert_not_nil assigns(:users)
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test 'should get index as json-api' do
    get :index, params: { format: :json_api }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_valid_json_api_response
    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert body['data'].any?
    assert_equal users_path, body['links']['self']
  end

  # User new is handled by devise
  test "should never allow user new route" do
    assert_raises(ActionController::UrlGenerationError) do
      get :new
    end
  end

  test "should be able to create user whilst logged in as admin" do
    sign_in users(:admin) # should this be restricted to admins?
    assert_difference('User.count') do
      post :create, params: {
        user: { username: 'frank', email: 'frank@notarealdomain.org', password: 'franksreallylongpass' }
      }
    end
    assert_redirected_to user_path(assigns(:user))
  end

  test "should not be able create user if not admin" do
    #because you use users#sign_up in devise
    assert_no_difference('User.count') do
      post :create, params: { user: { username: 'frank', email: 'frank@notarealdomain.org', password: 'franksreallylongpass' } }
    end
    assert_redirected_to new_user_session_path
    sign_in users(:regular_user)
    assert_no_difference('User.count') do
      post :create, params: { user: { username: 'frank', email: 'frank@notarealdomain.org', password: 'franksreallylongpass' } }
    end
    assert_response :forbidden
  end

  test "should show user if admin" do
    sign_in users(:admin)
    get :show, params: { id: @user }
    assert_response :success
  end

  test "should show other users page if not admin or self" do
    sign_in users(:another_regular_user)
    get :show, params: { id: @user }
    assert_response :success #FORBIDDEN PAGE!?
  end

  test "should show user with email address as username" do
    user = users(:email_address_user)
    sign_in user
    get :show, params: { id: user }
    assert_response :success
  end

  test "should show user as json" do
    sign_in users(:another_regular_user)
    get :show, params: { id: @user, format: 'json' }
    assert_response :success #FORBIDDEN PAGE!?
  end

  test 'should show user as json-api' do
    get :show, params: { id: @user, format: :json_api }
    assert_response :success
    assert assigns(:user)
    assert_valid_json_api_response
    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert_equal @user.profile.firstname, body['data']['attributes']['firstname']
    assert_equal user_path(assigns(:user)), body['data']['links']['self']
  end

  test "should only allow edit for admin and self" do
    sign_in users(:regular_user)
    get :edit, params: { id: @user }
    assert_response :success

    sign_in users(:admin)
    get :edit, params: { id: @user }
    assert_response :success

    sign_in users(:another_regular_user)
    get :edit, params: { id: @user }
    #assert_redirected_to root_path
  end

  test "should update profile" do
    sign_in users(:regular_user)
    patch :update, params: { id: @user, user: { profile_attributes: { email: 'hot@mail.com' } } }
    assert_redirected_to user_path(assigns(:user))
  end

  test "should reset token" do
    sign_in users(:regular_user)
    old_token = @user.authentication_token
    patch :change_token, params: { id: @user }
    new_token = User.find_by_username('Bob').authentication_token
    assert_not_equal old_token, new_token
  end

  test "should destroy user" do
    sign_in @user

    # Create default user that will be used as the new 'owner' of objects
    # after @user/real owner is destroyed. We are not really using it here
    # just making sure it is already in the DB so we can check number of users
    # after @user is deleted
    User.get_default_user

    assert_difference('User.count', -1) do
      delete :destroy, params: { id: @user }
    end
    assert_redirected_to users_path
  end

  test 'should change user role' do
    sign_in @admin
    assert_not_equal roles(:admin), @user.role

    patch :update, params: { id: @user, user: { role_id: roles(:admin).id } }

    assert_redirected_to user_path(assigns(:user))
    assert_equal roles(:admin), assigns(:user).role
  end

  test 'should change user role as js' do
    sign_in @admin
    assert_not_equal roles(:admin), @user.role

    patch :update, params: { id: @user, user: { role_id: roles(:admin).id }, format: :js }

    assert_response :success
    assert_equal roles(:admin), assigns(:user).role
  end

  test 'should not change user role if not an admin' do
    sign_in @user
    assert_not_equal roles(:admin), @user.role

    patch :update, params: { id: @user, user: { profile_attributes: { firstname: 'George' }, role_id: roles(:admin).id } }

    assert_redirected_to user_path(assigns(:user))
    assert_not_equal roles(:admin), assigns(:user).role
    assert_equal 'George', assigns(:user).profile.firstname
  end

  test 'should not update user if curator' do
    sign_in users(:curator)
    assert_not_equal roles(:curator), @user.role

    patch :update, params: { id: @user, user: { profile_attributes: { firstname: 'George' }, role_id: roles(:admin).id } }

    assert_response :forbidden
    assert_not_equal roles(:curator), assigns(:user).role
    assert_not_equal 'George', assigns(:user).profile.firstname
  end

  test 'should show ban info to admin' do
    user = users(:shadowbanned_user)
    sign_in users(:admin)
    get :show, params: { id: user }
    assert_response :success
    assert_select '.ban-info', count: 1
  end

  test 'should not show ban info to user' do
    user = users(:shadowbanned_user)
    sign_in user
    get :show, params: { id: user }
    assert_response :success
    assert_select '.ban-info', count: 0
  end

  test 'should show ban info from deleted user' do
    user = users(:shadowbanned_user)
    other_admin = users(:regular_user)
    user.ban.update_column(:banner_id, other_admin.id)
    other_admin.destroy!

    sign_in users(:admin)
    get :show, params: { id: user }

    assert_response :success
    assert_select '.ban-info' do
      assert_select 'p', text: 'By: Deleted user'
    end
  end

  test 'should update trainer profile' do
    user = users(:trainer_user)
    sign_in user

    # check profile
    get :show, params: { id: user }
    assert_response :success
    profile_old = assigns(:user).profile
    assert_equal true, profile_old.public
    assert_equal 'https://library.brown.edu/info/hay/carberry/', profile_old.website
    assert_equal 'Josiah Carberry', profile_old.full_name
    assert_equal 'jcarberry@research.org', profile_old.email
    assert profile_old.description.include?('Josiah Carberry is a fictitious person.')

    # update profile data
    profile = { public: false, email: 'fake@email.com', orcid: '', website: '', location: '',
                experience: 'expert', image_url: nil, expertise_technical: ['java', 'python', 'ruby'] }
    patch :update, params: { id: user, user: { profile_attributes: profile } }
    assert_redirected_to user_path(assigns(:user))

    # get user
    get :show, params: { id: user }
    assert_response :success
    profile_new = assigns(:user).profile
    assert_equal false, profile_new.public
    assert_equal 'fake@email.com', profile_new.email
    assert_nil profile_new.image_url
    assert_nil profile_new.orcid
    assert_nil profile_new.website
    assert_equal 3, profile_new.expertise_technical.size, 'expertise_technical array size not matchted.'
  end

  test 'should not update trainer profile for invalid public record' do
    user = users(:trainer_user)
    sign_in user

    # check validation for public fields
    profile_new = { public: true, first_name: '', last_name: '', description: '', website: '' }
    patch :update, params: { id: user, user: { profile_attributes: profile_new } }
    assert_response :success

    # check errors
    profile = assigns(:user).profile
    assert_equal 3, profile.errors.size, 'invalid number of errors'
    assert_equal 0, profile.errors.full_messages_for(:website).size, 'invalid message for: website'
    assert_equal 1, profile.errors.full_messages_for(:firstname).size, 'missing message for: firstname'
    assert_equal 1, profile.errors.full_messages_for(:surname).size, 'missing message for: surname'
    assert_equal 1, profile.errors.full_messages_for(:description).size, 'missing message for: description'
    assert_equal "Description can't be blank", profile.errors.full_messages_for(:description).first

  end

  test 'check orcid' do
    user = users(:trainer_user)
    sign_in user

    # check validation of invalid orcid
    profile_new = { orcid: 'https://orcid.org/000-0002-1825-0097x' }
    patch :update, params: { id: user, user: { profile_attributes: profile_new } }
    assert_response :success
    profile = assigns(:user).profile
    assert_equal 1, profile.errors.full_messages_for(:orcid).size, 'invalid error count for: orcid'
    assert_equal "ORCID isn't a valid ORCID identifier", profile.errors.full_messages_for(:orcid).first
  end

  test 'should not update trainer profile for invalid urls' do
    user = users(:trainer_user)
    sign_in user

    # check validation of urls
    profile_new = { website: 'httpx://dresa.org.au', orcid: 'https://orcid.org/000-0002-1825-0097x' }
    patch :update, params: { id: user, user: { profile_attributes: profile_new } }
    assert_response :success

    # check errors
    profile = assigns(:user).profile
    assert_equal 3, profile.errors.size, 'invalid number of errors'
    assert_equal 2, profile.errors.full_messages_for(:website).size, 'invalid error count for: website'
    assert_equal 1, profile.errors.full_messages_for(:orcid).size, 'invalid error count for: orcid'
    assert_equal "Website is not a valid URL", profile.errors.full_messages_for(:website).first
    assert_equal "ORCID isn't a valid ORCID identifier", profile.errors.full_messages_for(:orcid).first
  end

  test 'update profile to private' do
    user = users(:trainer_user)
    sign_in user

    # check type
    get :show, params: { id: user }
    assert_response :success
    profile = assigns(:user).profile
    assert_equal true, profile.public
    assert_equal 'Josiah Carberry', profile.full_name
    assert_equal 'Trainer', profile.type

    # update flag
    patch :update, params: { id: user, user: { profile_attributes: { public: false, firstname: profile.firstname,
                                                                     surname: profile.surname, email: profile.email,
                                                                     description: profile.description } } }
    assert assigns(:user).profile
    assert_equal 0, assigns(:user).profile.errors.size
    assert_response :redirect

    # recheck type
    get :show, params: { id: user }
    assert_response :success
    profile = assigns(:user).profile
    assert_equal false, profile.public
    assert_equal 'Profile', profile.type
  end

  test 'update profile to public' do
    user = users(:private_user)
    sign_in user

    # check type
    get :show, params: { id: user }
    assert_response :success
    profile = assigns(:user).profile
    assert_equal 'Lucifer MorningStar', profile.full_name
    assert_equal 'Profile', profile.type
    assert_equal false, profile.public

    # update flag
    patch :update, params: { id: user, user: { profile_attributes: { public: true, firstname: profile.firstname,
                                                                     surname: profile.surname, email: profile.email,
                                                                     description: profile.description } } }
    assert assigns(:user).profile
    assert_equal 0, assigns(:user).profile.errors.size
    assert_response :redirect

    # recheck type
    get :show, params: { id: user }
    assert_response :success
    puser = assigns(:user)
    assert puser
    assert_equal 'StevieN', puser.username
    profile = puser.profile
    assert_equal 'Lucifer MorningStar', profile.full_name
    assert_equal 'Trainer', profile.type
    assert_equal true, profile.public
  end

  test 'should be able to filter user index with a query' do
    get :index, params: { q: 'Reg' }

    assert_response :success
    assert assigns(:users).include?(users(:regular_user))
    refute assigns(:users).include?(users(:another_regular_user))
  end

  test 'should not show banned or basic users in index' do
    get :index
    assert_response :success
    all_users = assigns(:users).to_a
    assert users(:shadowbanned_user).banned?
    assert_not_includes all_users, users(:shadowbanned_user)
    assert_includes all_users, users(:unverified_user)
    assert_not_includes all_users, users(:basic_user)
    assert_includes all_users, users(:regular_user)
  end

  test 'should get invitees if feature enabled' do
    with_settings(feature: { invitation: true }) do
      sign_in @admin

      get :invitees

      assert_response :success
    end
  end

  test 'should not get invitees if feature disabled' do
    with_settings(feature: { invitation: false }) do
      sign_in @admin

      assert_raises(ActionController::RoutingError) do
        get :invitees
      end
    end
  end

  test 'should show tabs for resource types and link to view all' do
    sign_in(@user)

    assert @user.events.not_finished.count > 0
    assert @user.materials.count > 1
    assert @user.collections.count > 1
    assert @user.workflows.count > 1

    UsersHelper.stub(:user_profile_resource_limit, 1) do
      get :show, params: { id: @user }
    end

    # Tabs
    assert_select 'a[data-toggle="tab"]', text: "Events (#{@user.events.count})"
    assert_select 'a[data-toggle="tab"]', text: "Materials (#{@user.materials.count})"
    assert_select 'a[data-toggle="tab"]', text: "Collections (#{@user.collections.count})"
    assert_select 'a[data-toggle="tab"]', text: "Workflows (#{@user.workflows.count})"

    # Links
    assert_select '#events a[href=?]', events_path(user: @user.username)
    assert_select '#materials a[href=?]', materials_path(user: @user.username)
    assert_select '#collections a[href=?]', collections_path(user: @user.username)
    assert_select '#workflows a[href=?]', workflows_path(user: @user.username)
  end

  test 'link to view all in events tab should include_expired if user has no upcoming events' do
    user = users(:another_regular_user)
    sign_in(user)

    assert user.events.not_finished.none?
    assert user.events.any?

    UsersHelper.stub(:user_profile_resource_limit, 1) do
      get :show, params: { id: user }
    end

    assert_select 'a[data-toggle="tab"]', text: "Events (#{user.events.count})"
    assert_select '#events a[href=?]', events_path(user: user.username, include_expired: true)
  end

  test 'should be able to filter for new user with a query' do
    get :index, params: { q: 'unver' }

    assert_response :success
    assert assigns(:users).include?(users(:unverified_user))

    get :index, params: { q: 'naugh' }

    assert_response :success
    refute assigns(:users).include?(users(:shadowbanned_unverified_user))

    get :index, params: { q: 'basic' }

    assert_response :success
    refute assigns(:users).include?(users(:basic_user))
  end
end
