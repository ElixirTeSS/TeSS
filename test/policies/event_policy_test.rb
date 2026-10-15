require 'test_helper'

class EventPolicyTest < ActiveSupport::TestCase
  UserContext = Struct.new(:user)

  setup do
    @curator = users(:curator)
    @private_space = spaces(:private_space)
    @requested_private = events(:one)
    @requested_private.update_columns(
      space_id: @private_space.id,
      approval_status: Event::APPROVAL_STATUS_CODES[:requested]
    )
  end

  def resolve_scope(user)
    EventPolicy::Scope.new(UserContext.new(user), Event.all).resolve
  end

  test 'curator scope excludes requested events in a private space' do
    with_settings(feature: { event_under_admin_approval: true }) do
      refute_includes resolve_scope(@curator), @requested_private
    end
  end

  test 'space admin curator scope includes requested events in their private space' do
    with_settings(feature: { event_under_admin_approval: true }) do
      @curator.space_roles.create!(space: @private_space, key: 'admin')

      assert_includes resolve_scope(@curator), @requested_private
      assert Event.user_can_curate_unapproved_in_space?(@curator, @private_space)
    end
  end

  test 'curator can curate unapproved events in a public space' do
    with_settings(feature: { event_under_admin_approval: true }) do
      assert Event.user_can_curate_unapproved_in_space?(@curator, spaces(:plants))
    end
  end
end
