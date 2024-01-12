class LearningPathTopicLink < ApplicationRecord
  belongs_to :learning_path, touch: true
  belongs_to :topic, foreign_key: :topic_id, class_name: 'LearningPathTopic'

  before_create :set_order

  validates :topic_id, uniqueness: { scope: %i[learning_path_id], message: 'already included in learning path' }

  private

  def set_order
    self.order ||= (learning_path.topic_links.maximum(:order) || 0) + 1
  end
end
