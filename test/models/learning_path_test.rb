require 'test_helper'

class LearningPathTest < ActiveSupport::TestCase
  test 'visibility scope' do
    assert_not_includes LearningPath.visible_by(nil), learning_paths(:archived_learning_path)
    assert_not_includes LearningPath.visible_by(users(:another_regular_user)), learning_paths(:archived_learning_path)
    assert_includes LearningPath.visible_by(users(:regular_user)), learning_paths(:archived_learning_path)
    assert_includes LearningPath.visible_by(users(:admin)), learning_paths(:archived_learning_path)

    assert_includes LearningPath.visible_by(nil), learning_paths(:one)
    assert_includes LearningPath.visible_by(users(:another_regular_user)), learning_paths(:one)
    assert_includes LearningPath.visible_by(users(:regular_user)), learning_paths(:one)
    assert_includes LearningPath.visible_by(users(:admin)), learning_paths(:one)
  end

  test 'add topic to learning path' do
    learning_path = learning_paths(:in_development_learning_path)
    topic = learning_path_topics(:good_and_bad)
    assert_empty learning_path.topics

    assert_difference('LearningPathTopicLink.count', 1) do
      learning_path.topics << topic
    end

    assert learning_path.topics.include?(topic)
  end

  test 'remove topic from learning path' do
    learning_path = learning_paths(:in_development_learning_path)
    topic = learning_path_topics(:good_and_bad)
    learning_path.topics << topic

    refute_empty learning_path.reload.topics
    assert_difference('LearningPathTopicLink.count', -1) do
      learning_path.topics = []
    end

    assert_not_includes learning_path.topics, topic
  end

  test 'cannot add duplicates to learning_path' do
    learning_path = learning_paths(:in_development_learning_path)
    topic = learning_path_topics(:good_and_bad)
    learning_path.topics << topic

    refute_empty learning_path.reload.topics
    assert_no_difference('LearningPathTopicLink.count') do
      assert_raises(ActiveRecord::RecordInvalid) do
        learning_path.topics << topic
      end
    end
  end

  test 'clean up topic links when learning path destroyed' do
    learning_path = learning_paths(:one)
    assert_equal 2, learning_path.topics.count
    assert_equal 5, learning_path.topics_materials.count

    assert_no_difference('LearningPathTopic.count') do
      assert_no_difference('LearningPathTopicItem.count') do
        assert_no_difference('Material.count') do
          assert_difference('LearningPathTopicLink.count', -2) do
            assert learning_path.destroy
          end
        end
      end
    end
  end

  test 'should strip attributes' do
    mock_images
    learning_path = learning_paths(:one)
    assert learning_path.update(title: ' LearningPath  Title  ', description: " some text\n")
    assert_equal 'LearningPath  Title', learning_path.title
    assert_equal 'some text', learning_path.description
  end

  test 'should normalize order of topics' do
    learning_path = learning_paths(:in_development_learning_path)
    learning_path.topic_links.create!(topic: learning_path_topics(:good_and_bad), order: 96)
    learning_path.topic_links.create!(topic: learning_path_topics(:goblet_things), order: 4)
    learning_path.save!

    assert_equal [1, 2], learning_path.topic_links.pluck(:order)
    assert_equal [learning_path_topics(:goblet_things), learning_path_topics(:good_and_bad)], learning_path.topic_links.map(&:topic)
  end
end
