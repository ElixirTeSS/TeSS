require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  test 'visibility scope' do
    assert_not_includes Collection.visible_by(nil), collections(:secret_collection)
    assert_not_includes Collection.visible_by(users(:another_regular_user)), collections(:secret_collection)
    assert_includes Collection.visible_by(users(:regular_user)), collections(:secret_collection)
    assert_includes Collection.visible_by(users(:admin)), collections(:secret_collection)

    assert_includes Collection.visible_by(nil), collections(:one)
    assert_includes Collection.visible_by(users(:another_regular_user)), collections(:one)
    assert_includes Collection.visible_by(users(:regular_user)), collections(:one)
    assert_includes Collection.visible_by(users(:admin)), collections(:one)
  end

  test 'user_requires_approval?' do
    user = users(:unverified_user)

    first_collection = user.collections.build(title: 'bla')
    assert first_collection.user_requires_approval?
    assert first_collection.from_unverified_or_rejected?
    first_collection.save!

    second_collection = user.collections.build(title: 'bla')
    refute second_collection.user_requires_approval?
  end

  test 'from_unverified_or_rejected?' do
    user = users(:unverified_user)

    first_collection = user.collections.create!(title: 'bla')
    assert first_collection.from_unverified_or_rejected?

    user.role = Role.rejected
    user.save!

    second_collection = user.collections.create(title: 'bla')
    assert second_collection.from_unverified_or_rejected?

    user.role = Role.approved
    user.save!

    third_collection = user.collections.create(title: 'bla')
    refute third_collection.from_unverified_or_rejected?
  end
end
