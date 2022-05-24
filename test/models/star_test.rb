require 'test_helper'

class StarTest < ActiveSupport::TestCase

  test 'can create star' do
    star = Star.new(resource: materials(:good_material), user: users(:regular_user))
    assert star.valid?
  end

  test 'cannot create duplicate star' do
    Star.create(resource: materials(:good_material), user: users(:regular_user))
    star = Star.new(resource: materials(:good_material), user: users(:regular_user))
    refute star.valid?
    assert star.errors[:resource_id].any?
  end

  test 'can create star for another resource of same type' do
    Star.create(resource: materials(:good_material), user: users(:regular_user))
    star = Star.new(resource: materials(:bad_material), user: users(:regular_user))
    assert star.valid?
  end

  test 'can create star for same resource as another user' do
    Star.create(resource: materials(:good_material), user: users(:regular_user))
    star = Star.new(resource: materials(:good_material), user: users(:another_regular_user))
    assert star.valid?
  end

  test 'cannot create star of non-existent resource' do
    star = Star.new(resource_id: Material.maximum(:id) + 1, resource_type: 'Material', user: users(:regular_user))
    refute star.valid?
    assert star.errors[:resource].any?
  end
end
