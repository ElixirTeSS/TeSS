require 'test_helper'

class ActivitiesControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  test 'should get activities for a material' do
    material = materials(:good_material)
    assert_difference('PublicActivity::Activity.count', 1) do
      material.description = 'New description'
      material.save!
    end

    other_material = materials(:biojs)
    assert_difference('PublicActivity::Activity.count', 2) do # Slug updates as well
      other_material.description = 'Other description'
      other_material.save!
    end

    assert_equal 1, material.activities.count
    get :index, params: { material_id: materials(:good_material).id }
    assert_response :success
    assert_select '.activity', count: 1
    assert_select '.activity .sub-activity' do
      assert_select 'em', 'Description'
      assert_select 'strong', 'New description'
    end
  end

  test 'should not show report-related event parameter changes to non-privileged users' do
    event = events(:event_with_report)
    sign_in users(:another_regular_user)
    assert_difference('PublicActivity::Activity.count', 2) do
      event.title = 'hello'
      event.funding = 'test'
      event.save!
    end

    get :index, params: { event_id: event }
    assert_select '.sub-activity', count: 1
    assert_select '.sub-activity em', text: /Funding/, count: 0
    assert_select '.sub-activity em', text: /Title/, count: 1
  end

  test 'should show report-related event parameter changes to privileged users' do
    event = events(:event_with_report)
    sign_in event.user
    assert_difference('PublicActivity::Activity.count', 2) do
      event.title = 'hello'
      event.funding = 'test'
      event.save!
    end

    get :index, params: { event_id: event }
    assert_select '.sub-activity', count: 2
    assert_select '.sub-activity em', text: /Funding/, count: 1
    assert_select '.sub-activity em', text: /Title/, count: 1
  end

  test 'should show approval status change activities for a source' do
    source = sources(:first_source)
    user = source.user
    User.current_user = user

    assert_difference('PublicActivity::Activity.count', 1) do
      source.request_approval
    end

    get :index, params: { source_id: source }

    assert_select '.activity span.label', text: 'Approval requested'
  end

  test 'should render each activity' do
    resources = {
      collection: collections(:one),
      content_provider: content_providers(:goblet),
      event: events(:one),
      learning_path: learning_paths(:one),
      learning_path_topic: learning_path_topics(:good_and_bad),
      learning_path_topic_item: learning_path_topic_items(:item1a),
      material: materials(:good_material),
      node: nodes(:good),
      source: sources(:first_source),
      user: users(:regular_user),
      workflow: workflows(:one)
    }

    resources[:collection].events << resources[:event]
    resources[:collection_item] = resources[:collection].items.first

    activities = {
    'collection.add_event' => { event_title: resources[:event].title, event_id: resources[:event].id },
    'collection.add_item' => { resource_type: 'Event', resource_title: resources[:event].title, resource_id: resources[:event].id },
    'collection.add_material' => { material_title: resources[:material].title, material_id: resources[:material].id },
    'collection.create' => {},
    'collection.destroy' => {},
    'collection.update' => {},
    'collection.update_parameter' => { attr: 'title', new_val: 'Hello' },

    'content_provider.create' => {},
    'content_provider.destroy' => {},
    'content_provider.update' => {},
    'content_provider.update_parameter' => { attr: 'title', new_val: 'Hello' },

    'event.add_data' => { data_field: 'geographic_coordinates', data_value: [25, 25] },
    'event.add_term' => { uri: 'http://edamontology.org/topic_3372', name: 'Software engineering', field: 'topics' },
    'event.add_to_collection' => { collection_title: resources[:collection].title, collection_id: resources[:collection].id },
    'event.create' => {},
    'event.destroy' => {},
    'event.reject_data' => { data_field: 'geographic_coordinates', data_value: [25, 25] },
    'event.reject_term' => { uri: 'http://edamontology.org/topic_3372', name: 'Software engineering', field: 'topics' },
    'event.report' => {},
    'event.update' => {},
    'event.update_parameter' => { attr: 'content_provider_id', association_name: 'new-provider!', new_val: resources[:content_provider].id },

    'learning_path.add_topic' => { topic_title: resources[:learning_path_topic].title, topic_id: resources[:learning_path_topic].id },
    'learning_path.create' => {},
    'learning_path.destroy' => {},
    'learning_path.update' => {},
    'learning_path.update_parameter' => { attr: 'title', new_val: 'Hello' },

    'learning_path_topic.add_item' => { resource_type: 'Material', resource_title: resources[:material].title, resource_id: resources[:material].id },
    'learning_path_topic.create' => {},
    'learning_path_topic.destroy' => {},
    'learning_path_topic.update' => {},
    'learning_path_topic.update_parameter' => { attr: 'title', new_val: 'Hello' },

    'material.add_data' => { data_field: 'title', data_value: 'Hello World!' },
    'material.add_term' => { uri: 'http://edamontology.org/topic_3372', name: 'Software engineering', field: 'topics' },
    'material.add_to_collection' => { collection_title: resources[:collection].title, collection_id: resources[:collection].id },
    'material.add_to_topic' => { topic_title: resources[:learning_path_topic].title, topic_id: resources[:learning_path_topic].id },
    'material.create' => {},
    'material.destroy' => {},
    'material.reject_data' => { data_field: 'title', data_value: 'Hello World!' },
    'material.reject_term' => { uri: 'http://edamontology.org/topic_3372', name: 'Software engineering', field: 'topics' },
    'material.update' => {},
    'material.update_parameter' => { attr: 'title', new_val: 'Hello' },

    'node.create' => {},
    'node.destroy' => {},
    'node.update' => {},
    'node.update_parameter' => { attr: 'title', new_val: 'Hello' },

    'source.approval_status_changed' => { old: 'not_approved', new: 'requested' },
    'source.create' => {},
    'source.destroy' => {},
    'source.update' => {},
    'source.update_parameter' => { attr: 'title', new_val: 'Hello' },

    'user.change_role' => { old: roles(:unverified_user).id, new: roles(:basic_user).id },
    'user.create' => {},
    'user.destroy' => {},
    'user.update' => {},
    'user.update_parameter' => { attr: 'title', new_val: 'Hello' },

    'workflow.create' => {},
    'workflow.destroy' => {},
    'workflow.modify_diagram' => {
      added_nodes: [{ 'data' => { 'name' => 'Node 1' } }, { 'data' => { 'name' => 'Node 2' } }],
      removed_nodes: [],
      modified_nodes: [{ 'data' => { 'name' => 'Node A' } }, { 'data' => { 'name' => 'Node B' } }],
    },
    'workflow.update' => {},
    'workflow.update_parameter' => { attr: 'title', new_val: 'Hello' }
    }

    user = users(:admin)
    sign_in(user)
    activities.each do |key, parameters|
      resource_key = key.split('.').first.to_sym
      resource = resources[resource_key]
      raise "Missing resource: #{resource_key}" unless resource
      activity = resource.activities.create!(key: key, owner: user, parameters: parameters)
      get :show, params: { id: activity.id }
      assert_response :success, "Error rendering #{key} activity"
    end
  end
end
