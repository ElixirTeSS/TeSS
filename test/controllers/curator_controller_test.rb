require 'test_helper'

class CuratorControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get topic suggestions if curator' do
    sign_in users(:curator)
    e1 = add_topic_suggestions(events(:one), ['Genomics', 'Animals'])
    e2 = add_topic_suggestions(materials(:good_material), ['Biology', 'Proteins'])
    add_topic_activity(materials(:good_material), EDAM::Ontology.instance.lookup_by_name('Proteins'), users(:curator))

    get :topic_suggestions

    assert_response :success
    assert_includes assigns(:suggestions), e1
    assert_includes assigns(:suggestions), e2
    assert_select 'div.score', text: 'You have made 1 contribution'
  end

  test 'should get topic suggestions if admin' do
    sign_in users(:admin)
    e1 = add_topic_suggestions(events(:one), ['Genomics', 'Animals'])
    e2 = add_topic_suggestions(materials(:good_material), ['Biology'])

    get :topic_suggestions

    assert_response :success
    assert_includes assigns(:suggestions), e1
    assert_includes assigns(:suggestions), e2
  end

  test 'should not get topic suggestions if regular user' do
    sign_in users(:regular_user)

    get :topic_suggestions

    assert_response :forbidden
    assert flash[:alert].include?('curator')
    assert_nil assigns(:suggestions)
  end

  test 'should get user curation page, but not allow role selection if curator' do
    sign_in users(:curator)

    get :users

    assert_response :success
    assert_includes assigns(:users), users(:unverified_user)
    assert_equal roles(:unverified_user), assigns(:role)

    get :users, params: { role: :basic_user }
    assert_response :success
    assert_not_includes assigns(:users), users(:basic_user)
    assert_not_equal roles(:basic_user), assigns(:role)
  end

  test 'should get user curation page, and allow role selection if admin' do
    sign_in users(:admin)

    get :users

    assert_response :success
    assert_includes assigns(:users), users(:unverified_user)
    assert_equal roles(:unverified_user), assigns(:role)

    get :users, params: { role: :basic_user }
    assert_response :success
    assert_includes assigns(:users), users(:basic_user)
    assert_equal roles(:basic_user), assigns(:role)
  end

  test 'should allow filtering out users without content' do
    sign_in users(:admin)
    new_user = users(:unverified_user)

    get :users, params: { with_content: true }

    assert_response :success
    assert_not_includes assigns(:users), new_user

    new_user.events.create!(title: 'Spam event', url: 'http://cool-event.pancakes', start: 10.days.from_now)

    get :users, params: { with_content: true }

    assert_response :success
    assert_includes assigns(:users), new_user
  end

  test 'should not get user curation page if regular user' do
    sign_in users(:regular_user)

    get :users

    assert_response :forbidden
    assert flash[:alert].include?('curator')
    assert_nil assigns(:suggestions)
  end

  test 'should show recent user approvals and rejections' do
    admin = users(:admin)
    approved = users(:unverified_user)
    rejected = users(:shadowbanned_unverified_user)

    sign_in admin
    User.current_user = admin # This is needed to set the correct "owner" on the activity logs
    assert approved.update_attributes(role_id: Role.approved.id)
    assert rejected.update_attributes(role_id: Role.rejected.id)

    get :users

    assert_response :success
    assert_select '#recent-user-curation-activity ul li', text: /#{approved.name}\s+was\s+approved\s+by\s+#{admin.username}/
    assert_select '#recent-user-curation-activity ul li', text: /#{rejected.name}\s+was\s+rejected\s+by\s+#{admin.username}/
  end


  private

  def add_topic_suggestions(resource, topic_names = [])
    resource.build_edit_suggestion.tap do |e|
      e.scientific_topic_names = topic_names
      e.save
    end
  end

  def add_topic_activity(resource, topic, user)
    log_params = { uri: topic.uri,
                   field: 'topics',
                   name: topic.preferred_label }

    resource.edit_suggestion.accept_suggestion('scientific_topics', topic)
    resource.create_activity :add_term,
                             owner: user,
                             recipient: resource.user,
                             parameters: log_params
  end

end
