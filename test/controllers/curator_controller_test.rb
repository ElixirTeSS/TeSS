require 'test_helper'

class CuratorControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get topic suggestions if curator' do
    sign_in users(:curator)
    e1 = add_topic_suggestions(events(:one), ['Genomics', 'Animals'])
    e2 = add_topic_suggestions(materials(:good_material), ['Biology'])

    get :topic_suggestions

    assert_response :success
    assert_includes assigns(:suggestions), e1
    assert_includes assigns(:suggestions), e2
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

  private

  def add_topic_suggestions(resource, topic_names = [])
    resource.build_edit_suggestion.tap do |e|
      e.scientific_topic_names = topic_names
      e.save
    end
  end

end
