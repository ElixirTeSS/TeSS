# frozen_string_literal: true

require 'test_helper'

class ActivitiesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get activities for a material' do
    get :index, params: { material_id: materials(:good_material).id }
    assert_response :success
  end

  test 'should not show report-related event parameter changes to non-privileged users' do
    event = events(:event_with_report)
    sign_in users(:another_regular_user)
    event.funding = 'test'
    event.save

    get :index, params: { event_id: event }
    assert_select '.sub-activity em', text: /Funding/, count: 0
  end

  test 'should show report-related event parameter changes to privileged users' do
    event = events(:event_with_report)
    sign_in event.user
    event.funding = 'test'
    event.save

    get :index, params: { event_id: event }
    assert_select '.sub-activity em', text: /Funding/, count: 1
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
