# frozen_string_literal: true

require 'test_helper'

class CollectionTest < ActiveSupport::TestCase
  teardown do
    DummyMaterial.clear_index!
  end

  class DummyMaterial < ::Material
    def self.index
      (@index ||= {}).values.flatten.uniq
    end

    def self.add_to_index(m)
      index
      @index[m.id] = m.reload.collections.to_a
    end

    def self.clear_index!
      @index = {}
    end

    def solr_index
      self.class.add_to_index(self)
    end
  end

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

  test 'add to collection' do
    collection = collections(:one)
    material = materials(:good_material)
    assert_difference('CollectionItem.count', 1) do
      collection.materials << material
    end

    assert_includes collection.materials, material
  end

  test 'remove from collection' do
    collection = collections(:one)
    material1 = materials(:good_material)
    material2 = materials(:training_material)
    collection.materials << material1
    collection.materials << material2

    assert_difference('CollectionItem.count', -1) do
      collection.materials = [material1]
    end

    assert_includes collection.materials, material1
    assert_not_includes collection.materials, material2
  end

  test 'cannot add duplicates to collection' do
    collection = collections(:one)
    material = materials(:good_material)
    collection.materials << material
    assert_no_difference('CollectionItem.count') do
      assert_raises(ActiveRecord::RecordInvalid) do
        collection.materials << material
      end
    end
  end

  test 'clean up items when collection destroyed' do
    collection = collections(:one)
    material1 = materials(:good_material)
    material2 = materials(:training_material)
    collection.materials << material1
    collection.materials << material2

    assert_difference('CollectionItem.count', -2) do
      assert collection.destroy
    end
  end

  test 'index collection resources when collection created or destroyed' do
    user = users(:regular_user)
    material = materials(:good_material).becomes(DummyMaterial)
    with_settings(solr_enabled: true) do
      collection = user.collections.create!(title: 'test 123', materials: [material])

      assert collection
      assert_includes DummyMaterial.index, collection
      assert_equal 1, DummyMaterial.index.length

      assert collection.destroy
      assert_equal 0, DummyMaterial.index.length
    end
  end

  test 'index collection resources when collection renamed' do
    user = users(:regular_user)
    material = materials(:good_material).becomes(DummyMaterial)
    collection = user.collections.create!(title: 'test 123', materials: [material])
    assert collection

    with_settings(solr_enabled: true) do
      assert_equal 0, DummyMaterial.index.length

      collection.update!(title: 'Hello world')
      assert_includes DummyMaterial.index, collection
      assert_equal 1, DummyMaterial.index.length
    end
  end

  test 'do not index collection resources when collection updated without renaming' do
    user = users(:regular_user)
    material = materials(:good_material).becomes(DummyMaterial)
    collection = user.collections.create!(title: 'test 123', materials: [material])
    assert collection

    with_settings(solr_enabled: true) do
      assert_equal 0, DummyMaterial.index.length

      collection.update!(description: 'hello')
      assert_equal 0, DummyMaterial.index.length
    end
  end
end
