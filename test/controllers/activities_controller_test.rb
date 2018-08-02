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

end
