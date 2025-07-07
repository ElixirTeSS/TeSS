require 'test_helper'

class SpaceTest < ActiveSupport::TestCase
  setup do
    @space = spaces(:plants)
  end

  test 'get administrators' do
    admins = @space.administrators
    assert_equal 1, admins.length
    assert_includes admins, users(:space_admin)
  end

  test 'set administrators' do
    user = users(:regular_user)
    another_user = users(:another_regular_user)

    assert_difference('SpaceRole.count', 1) do
      @space.administrators = [user, another_user]
    end

    admins = @space.administrators
    assert_equal 2, admins.length
    assert_includes admins, user
    assert_includes admins, another_user
    assert_not_includes admins, users(:space_admin)

    assert_difference('SpaceRole.count', -2) do
      @space.administrators = []
    end

    assert_empty @space.administrators
  end
end
