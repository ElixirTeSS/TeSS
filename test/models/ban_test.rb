require 'test_helper'

class BanTest < ActiveSupport::TestCase
  test 'can shadow ban a user' do
    user = users(:regular_user)
    banner = users(:admin)
    event = user.events.first

    refute user.shadowbanned?
    refute event.from_shadowbanned?

    assert_difference('Ban.count') do
      user.create_ban(banner_id: banner.id, reason: 'Being bad', shadow: true)
    end

    assert user.shadowbanned?
    assert event.reload.from_shadowbanned?
  end
end
