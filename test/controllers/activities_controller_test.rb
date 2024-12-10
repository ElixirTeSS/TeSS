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
end
