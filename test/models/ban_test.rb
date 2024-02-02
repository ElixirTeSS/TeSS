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

  test 'banner nullified when user destroyed' do
    user = users(:shadowbanned_user)
    ban = user.ban
    banner = ban.banner
    assert banner

    banner.destroy!

    assert_nil ban.reload.banner
  end
end
