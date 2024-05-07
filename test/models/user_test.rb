require 'test_helper'
require 'ostruct'

class UserTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    mock_images
    @user_data = users(:regular_user)
    @user_params = { username: 'new_user', password: '12345678', email: 'new-user@example.com', processing_consent: '1' }
    User.get_default_user
  end

  test "should save new user" do
    user = User.new(@user_params)
    assert user.save, "Did not save user"
  end

  test "should set default role after saving new user" do
    user = User.new(@user_params)
    assert_not_instance_of Role, user.role
    user.save
    assert_instance_of Role, user.role
    assert_equal 'registered_user', user.role.name
  end

  test 'default role should be configurable' do
    with_settings(default_role: 'basic_user') do
      user = User.create!(@user_params)
      assert_equal 'basic_user', user.role.name
    end

    with_settings(default_role: 'unverified_user') do
      user = User.create!({ username: 'new_user2',
                            password: '12345678',
                            email: 'new-user2@example.com',
                            processing_consent: '1' })
      assert_equal 'unverified_user', user.role.name
    end
  end

  test "should set default profile after saving new user" do
    user = User.new(@user_params)
    assert_not_instance_of Profile, user.profile
    user.save
    assert_instance_of Profile, user.profile
    assert_equal user.profile.user, user
  end

  test "should not save user with nil email" do
    user = User.new(@user_params.merge(email: nil))
    assert_not user.save, 'Saved user with nil e-mail address field'
    assert user.errors.added?(:email, :blank)
  end

  test "should not save user with empty email" do
    user = User.new(@user_params.merge(email: ''))
    assert_not user.save, 'Saved user with empty e-mail address field'
    assert user.errors.added?(:email, :blank)
  end

  test "should not save user without valid email format" do
    user = User.new(@user_params.merge(email: 'horse'))
    assert_not user.save, 'Saved user with invalid e-mail address'
    assert user.errors.added?(:email, :invalid, value: 'horse')
  end

  test "should convert user email to lowercase" do
    user = User.new(@user_params.merge(email: 'New.User@email.com'))
    assert user.save
    assert_equal 'new.user@email.com', user.reload.email
  end

  test "should not save user with nil processing consent" do
    user = User.new(@user_params.merge(processing_consent: nil))
    assert_not user.save, 'Saved user with nil processing_consent address field'
    assert user.errors.added?(:base, 'You must consent to TTI processing your data in order to register')
  end

  test "should not save user with processing consent equal to 0" do
    user = User.new(@user_params.merge(processing_consent: '0'))
    assert_not user.save, 'Saved user with processing_consent address field equal to "0"'
    assert user.errors.added?(:base, 'You must consent to TTI processing your data in order to register')
  end  
  
  test "should not save with nil password" do
    user = User.new(@user_params.merge(password: nil))
    assert user.password_required?
    refute user.using_omniauth?
    assert_not user.save, 'Saved user with no password'
    assert user.errors.added?(:password, :blank)
  end

  test "should save with nil password if using omniauth" do
    user = User.new(@user_params.merge(password: nil, provider: 'elixir_aai', uid: 'abcdefg'))
    refute user.password_required?
    assert user.using_omniauth?
    assert user.save
    assert user.reload.encrypted_password.blank?
  end

  test "should not save with password under 8 characters" do
    user = User.new(@user_params.merge(password: '1234567'))
    assert_not user.save, 'Allowed a user to have a password under 8 characters'
    assert user.errors.added?(:password, :too_short, count: 8)
  end

  test "should not save two users with same username" do
    user1 = User.new(@user_params.merge(email: "#{@user_data.email}2"))
    user2 = User.new(@user_params.merge(email: "#{@user_data.email}1"))
    assert user1.save, 'Did not save the first user'
    assert_not user2.save, 'Saved the second user with same username as first'
    assert user2.errors.added?(:username, :taken, value: @user_params[:username])
  end

  test "should not save two users with same case insensitive username" do
    user1 = User.new(@user_params.merge(email: "#{@user_data.email}2"))
    user2 = User.new(@user_params.merge(email: "#{@user_data.email}1", username: @user_params[:username].upcase))
    assert user1.save, 'Did not save the first user'
    assert_not user2.save, 'Saved the second user with same username as first'
    assert user2.errors.added?(:username, :taken, value: @user_params[:username].upcase)
  end

  test "should not save two users with same email" do
    user1 = User.new(@user_params.merge(username: "#{@user_data.username}2"))
    user2 = User.new(@user_params.merge(username: "#{@user_data.username}1"))
    assert user1.save, 'Did not save the first user'
    assert_not user2.save, 'Saved a second user with same e-mail address'
    assert user2.errors.added?(:email, :taken, value: @user_params[:email])
  end

  test "should not save user with case insensitive duplicate email" do
    user1 = User.new(@user_params.merge(username: "#{@user_data.username}2"))
    user2 = User.new(@user_params.merge(username: "#{@user_data.username}1", email: @user_params[:email].upcase))
    assert user1.save, 'Did not save the first user'
    assert_not user2.save, 'Saved a second user with same e-mail address'
    assert user2.errors.added?(:email, :taken, value: @user_params[:email])
  end

  test 'should destroy user' do
    user = users(:regular_user)
    assert_difference('User.count', -1) do
      user.destroy
    end
  end

  test 'should get full name' do
    assert_equal 'Reginald User', users(:regular_user).full_name
    assert_equal 'Anthony', users(:another_regular_user).full_name
    assert_nil User.new.full_name
  end

  test 'check if banned' do
    refute users(:regular_user).banned?
    refute users(:regular_user).shadowbanned?

    assert users(:banned_user).banned?
    refute users(:banned_user).shadowbanned?

    assert users(:shadowbanned_user).banned?
    assert users(:shadowbanned_user).shadowbanned?
  end

  test 'shadowbanned scope' do
    assert_includes User.shadowbanned, users(:shadowbanned_user)
    assert_not_includes User.shadowbanned, users(:regular_user)
  end

  test 'change email' do
    user = users(:regular_user)
    assert_no_difference('PublicActivity::Activity.count') do
      user.email = 'new-email@example.com'
      assert user.save
    end
  end

  test 'generates appropriate usernames from AAI auth info' do
    auth_info = OpenStruct.new({ nickname: 'coolguy1996', openid: 'coolguyinmcr', email: 'richard.smith@example.com' })
    refute User.where(username: 'coolguy1996').any?
    assert_equal 'coolguy1996', User.username_from_auth_info(auth_info)

    auth_info = OpenStruct.new({ openid: 'coolguyinmcr', email: 'richard.smith@example.com' })
    refute User.where(username: 'coolguyinmcr').any?
    assert_equal 'coolguyinmcr', User.username_from_auth_info(auth_info)

    auth_info = OpenStruct.new({ email: 'richard.smith@example.com' })
    refute User.where(username: 'richard.smith').any?
    assert_equal 'richard.smith', User.username_from_auth_info(auth_info)

    auth_info = OpenStruct.new({})
    refute User.where(username: 'user').any?
    assert_equal 'user', User.username_from_auth_info(auth_info)

    User.create({ username: 'user', password: '12345678', email: 'new-user@example.com', processing_consent: '1' })
    auth_info = OpenStruct.new({})
    assert User.where(username: 'user').any?
    refute User.where(username: 'user1').any?
    assert_equal 'user1', User.username_from_auth_info(auth_info)
  end

  test 'should log role change' do
    user = users(:regular_user)
    original_role = user.role
    new_role = roles(:admin)
    admin = users(:admin)
    User.current_user = admin

    assert_difference('PublicActivity::Activity.count', 1) do
      assert user.update(role_id: new_role.id)
    end

    assert_equal roles(:admin), user.reload.role
    activity = user.activities.last
    assert_equal admin, activity.owner
    assert_equal user, activity.trackable
    assert_equal 'user.change_role', activity.key
    assert_equal original_role.id, activity.parameters[:old]
    assert_equal new_role.id, activity.parameters[:new]
  end

  test 'unbanned and unverified scopes' do
    assert_includes User.unbanned, users(:regular_user)
    assert_includes User.unbanned, users(:unverified_user)
    assert_not_includes User.unbanned, users(:shadowbanned_user)
    assert_not_includes User.unbanned, users(:shadowbanned_unverified_user)

    assert_not_includes User.with_role('unverified_user'), users(:regular_user)
    assert_includes User.with_role('unverified_user'), users(:unverified_user)
    assert_not_includes User.with_role('unverified_user'), users(:shadowbanned_user)
    assert_includes User.with_role('unverified_user'), users(:shadowbanned_unverified_user)
    
    assert_not_includes User.unbanned.with_role('unverified_user'), users(:regular_user)
    assert_includes User.unbanned.with_role('unverified_user'), users(:unverified_user)
    assert_not_includes User.unbanned.with_role('unverified_user'), users(:shadowbanned_user)
    assert_not_includes User.unbanned.with_role('unverified_user'), users(:shadowbanned_unverified_user)

    assert_includes User.with_role('unverified_user', 'registered_user'), users(:regular_user)
    assert_includes User.with_role('unverified_user', 'registered_user'), users(:unverified_user)
  end

  test 'autocompleting users' do
    user = users(:regular_user)
    another = users(:another_regular_user)
    basic = users(:basic_user)

    # Should match on username
    assert_includes User.with_query('bo'), user
    assert_includes User.with_query('BO'), user
    assert_includes User.with_query('bO'), user
    assert_includes User.with_query('Bo'), user
    assert_not_includes User.with_query('Bo'), another
    assert_includes User.with_query('Bob'), user
    assert_not_includes User.with_query('Boba'), user

    # Should match on first name
    assert_includes User.with_query('Regi'), user
    assert_not_includes User.with_query('Regi'), another
    assert_includes User.with_query('Ant'), another

    # Should match on last name
    assert_includes User.with_query('User'), user

    # Should be chainable (so can exclude unverified users)
    assert_includes User.with_query('basic'), basic
    assert_not_includes User.with_role('registered_user').with_query('basic'), basic
  end

  test 'reassigns resources when deleted' do
    user = users(:regular_user)
    event = events(:one)
    material = materials(:good_material)
    workflow = workflows(:one)
    content_provider = content_providers(:goblet)
    source = sources(:unapproved_source)
    collection = collections(:one)
    node = nodes(:good)
    learning_path = learning_paths(:one)
    learning_path_topic = learning_path_topics(:good_and_bad)

    assert_equal user, event.user
    assert_equal user, material.user
    assert_equal user, workflow.user
    assert_equal user, content_provider.user
    assert_equal user, source.user
    assert_equal user, collection.user
    assert_equal user, node.user

    user.destroy!

    default_user = User.get_default_user
    assert_equal default_user, event.reload.user
    assert_equal default_user, material.reload.user
    assert_equal default_user, workflow.reload.user
    assert_equal default_user, content_provider.reload.user
    assert_equal default_user, source.reload.user
    assert_equal default_user, collection.reload.user
    assert_equal default_user, node.reload.user

    admin = users(:admin)
    assert_equal admin, learning_path.user
    assert_equal admin, learning_path_topic.user
    admin.destroy!
    assert_equal default_user, learning_path.reload.user
    assert_equal default_user, learning_path_topic.reload.user
  end

  test 'merge users' do
    user1 = User.create!(username: 'base_user', password: '12345678', email: 'base-user@example.com',
                         processing_consent: '1', profile_attributes: {
        expertise_technical: ['Python', 'Ruby', 'R'],
        firstname: 'John', surname: 'Userton'
      })
    user1_id = user1.id
    user2 = User.create!(username: 'merge_user', password: 'xyz123456', email: 'merge-user@example.com',
                         processing_consent: '1', profile_attributes: {
        firstname: 'J', surname: 'U',
        expertise_technical: ['Java', 'Python', 'R'],
        orcid: 'https://orcid.org/0000-0002-1825-0097'
      })
    user3 = User.create!(username: 'merge_user2', password: 'qwertyqwerty', email: 'merge-user2@example.com',
                         processing_consent: '1', profile_attributes: {
        orcid: 'https://orcid.org/0000-0001-9842-9718',
        description: 'Cool guy',
        expertise_technical: []
      })

    # Resources
    material1 = user1.materials.create!(title: 'material 1', url: 'https://training.com/materials/1', description: 'material1')
    material2 = user2.materials.create!(title: 'material 2', url: 'https://training.com/materials/2', description: 'material2')
    event1 = user2.events.create!(title: 'event 1', url: 'https://training.com/events/1')
    event2 = user3.events.create!(title: 'event 2', url: 'https://training.com/events/2')

    # Activity
    admin = users(:admin)
    User.current_user = admin
    assert_difference('PublicActivity::Activity.count', 1) do
      assert user2.update(role_id: Role.rejected.id)
    end
    activity1 = PublicActivity::Activity.last # As trackable
    assert_equal admin, activity1.owner
    assert_equal user2, activity1.trackable
    activity2 = event2.create_activity(:create, owner: user3) # As owner
    assert_equal user3, activity2.owner
    assert_equal event2, activity2.trackable

    # Subscriptions
    subscription1 = user2.subscriptions.create!(frequency: :daily, query: 'test', subscribable_type: 'Material')
    subscription2 = user2.subscriptions.create!(frequency: :weekly, query: 'test', subscribable_type: 'Event')

    # Approved editors
    provider = content_providers(:goblet)
    provider.add_editor(user1)
    provider.add_editor(user2)
    provider2 = content_providers(:iann)
    provider2.add_editor(user2)
    provider3 = content_providers(:two)
    provider3.add_editor(user3)

    # Collaborations
    workflow1 = workflows(:one)
    workflow2 = workflows(:two)
    workflow1.collaborators << user1
    workflow1.collaborators << user2
    workflow2.collaborators << user3

    # Test
    assert_no_difference('Event.count') do
    assert_no_difference('Material.count') do
    assert_no_difference('Subscription.count') do
    assert_difference('provider.editors.count', -1) do
    assert_no_difference('provider2.editors.count') do
    assert_no_difference('provider3.editors.count') do
    assert_difference('Collaboration.count', -1) do
    assert_difference('User.count', -2) do
      assert user1.merge(user2, user3)
      assert user2.reload.destroy
      assert user3.reload.destroy
    end
    end
    end
    end
    end
    end
    end
    end

    assert_equal 'base_user', user1.username
    assert_equal user1_id, user1.id
    assert_equal 'base-user@example.com', user1.email
    profile = user1.profile
    assert_equal 'John', profile.firstname
    assert_equal 'Userton', profile.surname
    assert_equal 'https://orcid.org/0000-0002-1825-0097', profile.orcid
    assert_equal 'Cool guy', profile.description
    assert_equal ['Python', 'Ruby', 'R', 'Java'], profile.expertise_technical

    assert_includes user1.materials, material1
    assert_includes user1.materials, material2
    assert_includes user1.events, event2
    assert_includes user1.events, event2

    assert_equal user1, activity1.reload.trackable
    assert_equal user1, activity2.reload.owner

    assert_equal user1, subscription1.reload.user
    assert_equal user1, subscription2.reload.user

    assert_equal [user1], provider.reload.editors
    assert_equal [user1], provider2.reload.editors
    assert_equal [user1], provider3.reload.editors

    assert_equal [user1], workflow1.reload.collaborators.to_a
    assert_equal [user1], workflow2.reload.collaborators.to_a
  end

  test 'email but not username is downcased on save' do
    user = users(:upcase_username_and_email)
    assert_equal 'MixedCaseUsername', user.username
    assert_equal 'MixedCaseEmail@example.com', user.email
    assert user.save
    assert_equal 'MixedCaseUsername', user.username
    assert_equal 'mixedcaseemail@example.com', user.email
  end

  test 'should strip attributes' do
    user = User.new(@user_params.merge(username: ' space ', email: ' new-user@example.com '))
    assert user.save
    assert_equal 'space', user.username
    assert_equal 'new-user@example.com', user.email
  end

  test 'should not send confirmation email when creating default user' do
    User.get_default_user.update!(role_id: Role.approved.id,
                                  username: 'default_user2',
                                  email: 'defaultuser2@example.com')

    assert_no_enqueued_emails do
      with_settings(force_user_confirmation: true) do
        assert_difference('User.count', 1) do
          User.create_default_user
        end
      end
    end
  end
end
