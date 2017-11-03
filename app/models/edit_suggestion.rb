class EditSuggestion < ActiveRecord::Base
  belongs_to :suggestible, polymorphic: true

  include HasScientificTopics

  def accept_suggestion(topic)
    if drop_topic(topic)
      self.suggestible.scientific_topics = self.suggestible.scientific_topics.push(topic)
      self.suggestible.save!
      self.destroy if self.scientific_topics.empty?
    end
  end

  def reject_suggestion(topic)
    if drop_topic(topic)
      self.destroy if self.scientific_topics.empty?
    end
  end

  private

  def drop_topic(topic)
    topics = self.scientific_topics
    unless (found_topic = topics.delete(topic)).nil?
      self.scientific_topics = topics
      self.save!
      found_topic
    end
  end
end
