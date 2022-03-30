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

end
