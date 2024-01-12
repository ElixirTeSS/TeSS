require 'test_helper'

class CuratorControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get topic suggestions if curator' do
    sign_in users(:curator)
    e1 = add_topic_suggestions(events(:one), ['Genomics', 'Animals'])
    e2 = add_topic_suggestions(materials(:good_material), ['Biology', 'Proteins'])
    add_topic_activity(materials(:good_material), Edam::Ontology.instance.lookup_by_name('Proteins'), users(:curator))

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
    e3 = add_topic_suggestions(workflows(:one), ['Proteins'])

    get :topic_suggestions

    assert_response :success
    assert_includes assigns(:suggestions), e1
    assert_includes assigns(:suggestions), e2
    assert_includes assigns(:suggestions), e3
  end

  test 'should not get topic suggestions if regular user' do
    sign_in users(:regular_user)

    get :topic_suggestions

    assert_response :forbidden
    assert_select '#error-message', text: /curator/
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

    e = new_user.events.create!(title: 'Spam event', url: 'http://cool-event.pancakes', start: 10.days.from_now,
                                description: "test event", organizer: "test organizer", end: 11.days.from_now,
                                eligibility: [ 'registration_of_interest' ], host_institutions: [ "MIT" ],
                                contact: "me", online: true, timezone: 'UTC'
                                )
    e.create_activity(:create, owner: new_user)

    get :users, params: { with_content: true }

    assert_response :success
    assert_includes assigns(:users), new_user
  end

  test 'should not get user curation page if regular user' do
    sign_in users(:regular_user)

    get :users

    assert_response :forbidden
    assert_select '#error-message', text: /curator/
    assert_nil assigns(:suggestions)
  end

  test 'should show recent user approvals and rejections' do
    admin = users(:admin)
    approved = users(:unverified_user)
    rejected = users(:shadowbanned_unverified_user)

    sign_in admin
    User.current_user = admin # This is needed to set the correct "owner" on the activity logs
    assert approved.update(role_id: Role.approved.id)
    assert rejected.update(role_id: Role.rejected.id)

    get :users

    assert_response :success
    assert_select '#recent-user-curation-activity ul li', text: /#{approved.name}\s+was\s+approved\s+by\s+#{admin.username}/
    assert_select '#recent-user-curation-activity ul li', text: /#{rejected.name}\s+was\s+rejected\s+by\s+#{admin.username}/
  end

  test 'should show all possible resource types under user' do
    sign_in users(:admin)
    new_user = users(:unverified_user)

    event = nil
    material = nil
    workflow = nil
    collection = nil
    provider = nil
    source = nil
    node = nil
    4.times do |i|
      e = new_user.events.create!(title: "Spam event #{i}", url: "http://cool-event.pancakes/#{i}", start: 10.days.from_now,
                                  description: "test event", organizer: "test organizer", end: 11.days.from_now,
                                  eligibility: [ 'registration_of_interest' ], host_institutions: [ "MIT" ],
                                  contact: "me", online: true, timezone: 'UTC')
      e.create_activity(:create, owner: new_user)
      event = e
    end

    4.times do |i|
      m = new_user.materials.create!(title: "Spam material #{i}", url: "http://cool-material.pancakes/#{i}", description: 'material')
      m.create_activity(:create, owner: new_user)
      material = m
    end

    4.times do |i|
      w = new_user.workflows.create!(title: "Spam workflow #{i}")
      w.create_activity(:create, owner: new_user)
      workflow = w
    end

    4.times do |i|
      c = new_user.collections.create!(title: "Spam collection #{i}")
      c.create_activity(:create, owner: new_user)
      collection = c
    end

    4.times do |i|
      p = new_user.content_providers.create!(title: "Spam provider #{i}", url: "https://provider.com/#{i}")
      p.create_activity(:create, owner: new_user)
      provider = p
    end

    4.times do |i|
      s = new_user.sources.create!(url: "https://sources.com/#{i}", method: 'event_csv',
                                   content_provider_id: provider.id)
      s.create_activity(:create, owner: new_user)
      source = s
    end

    4.times do |i|
      n = new_user.nodes.create!(name: "Node#{i}", country_code: 'ES')
      n.create_activity(:create, owner: new_user)
      node = n
    end

    get :users, params: { with_content: true }

    assert_response :success
    assert_includes assigns(:users), new_user
    assert_select '.panel-heading a[href=?]', @controller.user_path(new_user), text: new_user.username

    (User::CREATED_RESOURCE_TYPES - [:learning_paths, :learning_path_topics]).each do |type|
      klass = type.to_s.classify.constantize
      assert_select '.curate-user strong', { text: klass.model_name.human },
                    "#{klass.name.pluralize} missing from list of resources"
      assert_select '.curate-user a[href=?]', @controller.polymorphic_path(type, user: new_user.username),
                    text: "See all 4 #{klass.model_name.human.pluralize}"
    end

    [event, material, workflow, collection, provider, source, node].each do |resource|
      assert_select '.curate-user a[href=?]', @controller.polymorphic_path(resource), { text: resource.title },
                    "#{@controller.polymorphic_path(resource)} not found!, \nBody:\n#{response.body}"
    end
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
