require 'test_helper'

class SpaceRoleTest < ActiveSupport::TestCase
  setup do
    @space = spaces(:plants)
  end

  test 'validates role key' do
    invalid_key = @space.space_roles.build(user: users(:regular_user), key: :yes)
    refute invalid_key.valid?
    assert invalid_key.errors.added?(:key, :inclusion, value: 'yes')

    valid_key = @space.space_roles.build(user: users(:regular_user), key: :admin)
    assert valid_key.valid?
  end

  test 'can retrieve list of users with a given role in a space' do
    user = users(:regular_user)
    another_user = users(:another_regular_user)
    @space.space_roles.create!(user: user, key: :admin)
    @space.space_roles.create!(user: another_user, key: :admin)

    admins = @space.with_space_role?(:admin)
    assert_equal 2, admins.length
    assert_includes admins, user
    assert_includes admins, another_user

    assert_equal 2, @space.with_space_role?('admin').length

    assert_empty @space.with_space_role?(:badmin)
  end

  test 'can check if a user has a given role in a space' do
    user = users(:regular_user)
    another_user = users(:another_regular_user)
    @space.space_roles.create!(user: user, key: :admin)

    assert user.has_space_role?(@space, :admin)
    assert user.has_space_role?(@space, 'admin')
    refute user.has_space_role?(spaces(:astro), :admin)
    refute user.has_space_role?(@space, :overlord)
    refute another_user.has_space_role?(@space, :admin)
  end
end
