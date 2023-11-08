class LearningPathTopicItem < ApplicationRecord
  include PublicActivity::Model
  include LogParameterChanges

  belongs_to :resource, polymorphic: true
  belongs_to :topic, foreign_key: :topic_id, class_name: 'LearningPathTopic', touch: true
  validates :resource_id, uniqueness: { scope: %i[resource_type topic_id], message: 'already included in topic' }

  before_create :set_order
  after_save :log_activity

  def log_activity
    self.topic.create_activity(:add_item, owner: User.current_user,
                               parameters: { resource_id: self.resource_id,
                                             resource_type: self.resource_type,
                                             resource_title: self.resource.title })
    self.resource.create_activity(:add_to_topic, owner: User.current_user,
                                  parameters: { topic_id: self.topic_id,
                                                topic_title: self.topic.title })
  end

  private

  def set_order
    self.order ||= (topic.items.maximum(:order) || 0) + 1
  end
end
