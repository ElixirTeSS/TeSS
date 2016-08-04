module HasScientificTopics

  extend ActiveSupport::Concern

  included do
    has_many :scientific_topic_links, as: :resource
    has_many :scientific_topics, through: :scientific_topic_links
  end

  def scientific_topic_names= names
    self.scientific_topics = ScientificTopic.where(preferred_label: names)
  end

  def scientific_topic_names
    scientific_topics.map(&:preferred_label)
  end

end
