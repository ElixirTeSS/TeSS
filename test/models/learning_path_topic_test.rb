require 'test_helper'

class LearningPathTopicTest < ActiveSupport::TestCase
  test 'add to learning_path_topic' do
    learning_path_topic = learning_path_topics(:empty_topic)
    material = materials(:good_material)
    assert_difference('LearningPathTopicItem.count', 1) do
      learning_path_topic.materials << material
    end

    assert learning_path_topic.materials.include?(material)
  end

  test 'remove from learning_path_topic' do
    learning_path_topic = learning_path_topics(:empty_topic)
    material1 = materials(:good_material)
    material2 = materials(:training_material)
    learning_path_topic.materials << material1
    learning_path_topic.materials << material2

    assert_difference('LearningPathTopicItem.count', -1) do
      learning_path_topic.materials = [material1]
    end

    assert_includes learning_path_topic.materials, material1
    assert_not_includes learning_path_topic.materials, material2
  end

  test 'cannot add duplicates to learning_path_topic' do
    learning_path_topic = learning_path_topics(:empty_topic)
    material = materials(:good_material)
    learning_path_topic.materials << material
    assert_no_difference('LearningPathTopicItem.count') do
      assert_raises(ActiveRecord::RecordInvalid) do
        learning_path_topic.materials << material
      end
    end
  end

  test 'clean up items when learning_path_topic destroyed' do
    learning_path_topic = learning_path_topics(:empty_topic)
    material1 = materials(:good_material)
    material2 = materials(:training_material)
    learning_path_topic.materials << material1
    learning_path_topic.materials << material2

    assert_difference('LearningPathTopicItem.count', -2) do
      assert learning_path_topic.destroy
    end
  end

  test 'should strip attributes' do
    mock_images
    learning_path_topic = learning_path_topics(:empty_topic)
    assert learning_path_topic.update(title: ' LearningPathTopic  Title  ', description: " yay yaaaay\n")
    assert_equal 'LearningPathTopic  Title', learning_path_topic.title
    assert_equal 'yay yaaaay', learning_path_topic.description
  end

  test 'should normalize order of items' do
    learning_path_topic = learning_path_topics(:empty_topic)
    learning_path_topic.items.create!(resource: materials(:biojs), order: 2)
    learning_path_topic.items.create!(resource: materials(:interpro), order: 3)
    learning_path_topic.items.create!(resource: events(:one), order: 42)
    learning_path_topic.items.create!(resource: events(:two), order: 13)
    learning_path_topic.save!

    assert_equal [1, 2], learning_path_topic.material_items.pluck(:order)
    assert_equal [materials(:biojs), materials(:interpro)], learning_path_topic.material_items.map(&:resource)
    assert_equal [1, 2], learning_path_topic.event_items.pluck(:order)
    assert_equal [events(:two), events(:one)], learning_path_topic.event_items.map(&:resource)
  end
end
