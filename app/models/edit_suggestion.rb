class EditSuggestion < ActiveRecord::Base
  belongs_to :suggestible, polymorphic: true
  after_create :init_data_fields

  has_ontology_terms(:scientific_topics, branch: OBO_EDAM.topics)

  # data_fields: json field for storing any additional parameters
  # such as latitude, longitude &c.

  def init_data_fields
    self.data_fields = {} if data_fields.nil?
  end

  def accept_suggestion(topic)
    if drop_topic(topic)
      self.suggestible.scientific_topics = self.suggestible.scientific_topics.push(topic)
      self.suggestible.save!
      self.destroy if self.scientific_topics.empty? && !data
    end
  end

  def reject_suggestion topic
    if drop_topic(topic)
      self.destroy if self.scientific_topics.empty? && !data
    end
  end

  def drop_topic(topic)
    topics = self.scientific_topics
    unless (found_topic = topics.delete(topic)).nil?
      self.scientific_topics = topics
      self.save!
      found_topic
    end
  end

  def accept_data(field)
    if self.suggestible.update_attribute(field, data_fields[field])
      data_fields.delete(field)
      save!
      destroy if (scientific_topic_links.nil? || scientific_topic_links.empty?) && !data
    end
  end

  def reject_data(field)
    data_fields.delete(field)
    save!
    destroy if (scientific_topic_links.nil? || scientific_topic_links.empty?) && !data
  end

  def data
    return false if data_fields.nil? || data_fields.empty?
    true
  end
end
