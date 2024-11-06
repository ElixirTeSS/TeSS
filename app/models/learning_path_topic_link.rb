class LearningPathTopicLink < ApplicationRecord
  belongs_to :learning_path, touch: true
  belongs_to :topic, foreign_key: :topic_id, class_name: 'LearningPathTopic'

  before_create :set_order
  after_save :log_activity

  validates :topic_id, uniqueness: { scope: %i[learning_path_id], message: 'already included in learning path' }

  def previous_topic
    learning_path.topic_links.where(order: order - 1).first
  end

  def next_topic
    learning_path.topic_links.where(order: order + 1).first
  end

  private

  def set_order
    self.order ||= (learning_path.topic_links.maximum(:order) || 0) + 1
  end

  def log_activity
    self.learning_path.create_activity(:add_topic, owner: User.current_user,
                                       parameters: { topic_id: topic.id, topic_title: topic.title })
  end
end
