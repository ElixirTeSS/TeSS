class LearningPathsTopic < ApplicationRecord
  belongs_to :learning_path, touch: true
  belongs_to :topic, class_name: 'Collection'

  before_create :set_order

  private

  def set_order
    self.order ||= (learning_path.learning_paths_topics.maximum(:order) || 0) + 1
  end
end
