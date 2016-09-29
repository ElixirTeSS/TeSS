module HasScientificTopics

  extend ActiveSupport::Concern

  included do
    has_many :scientific_topic_links, as: :resource
    has_many :scientific_topics, through: :scientific_topic_links
  end

  def scientific_topic_names= names
    topics = []

    [names].flatten.each do |name|
      st = ScientificTopic.where(preferred_label: name).to_a
      st = ScientificTopic.where("'#{name}' = ANY (has_exact_synonym)").to_a if st.empty?
      st = ScientificTopic.where("'#{name}' = ANY (has_narrow_synonym)").to_a if st.empty?
      topics << st
    end

    self.scientific_topics = topics.flatten.uniq
  end

  def scientific_topic_names
    scientific_topics.map(&:preferred_label)
  end

end
