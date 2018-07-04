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
      suggestible.scientific_topics = (suggestible.scientific_topics << topic)
      suggestible.save!
      destroy if redundant?
    end
  end

  def reject_suggestion(topic)
    if drop_topic(topic)
      destroy if redundant?
    end
  end

  def accept_data(field)
    if suggestible.update_attribute(field, data_fields[field])
      data_fields.delete(field)
      save!
      destroy if redundant?
    end
  end

  def reject_data(field)
    data_fields.delete(field)
    save!
    destroy if redundant?
  end

  def data
    !data_fields.blank?
  end

  private

  def drop_topic(topic)
    topics = scientific_topics
    unless (found_topic = topics.delete(topic)).nil?
      self.scientific_topics = topics
      save!
      found_topic
    end
  end

  def redundant?
    scientific_topic_links.empty? && !data
  end
end
