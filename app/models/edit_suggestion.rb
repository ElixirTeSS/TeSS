class EditSuggestion < ActiveRecord::Base
  belongs_to :suggestible, polymorphic: true

  include HasScientificTopics

  # data_fields: json field for storing any additional parameters
  # such as latitude, longitude &c.

  def accept_suggestion resource, topic
    resource.scientific_topics = resource.scientific_topics.push(topic)
    if resource.save!
      suggestions = drop_topic({uri: topic.uri})
      destroy if (suggestions.nil? || suggestions.empty?) && !data
    end
  end

  def reject_suggestion topic
    suggestions = self.drop_topic({uri: topic.uri})
    destroy if suggestions.empty? && !data
  end

  #Params: :uri => http://edamontology.org/3023
  #        :name => 'RNA-Seq'
  def drop_topic options={}
    return nil if options[:uri].nil?
    topics = self.scientific_topics
    topic_index = topics.index{|x| x.uri == options[:uri]}
    if topic_index
      topics.delete_at(topic_index)
      self.scientific_topics = topics
      self.save!
      return self.scientific_topics
    else
      return nil
    end

  end

  def accept_data resource, field, value
    resource[field.to_sym] = value
    if resource.save!
      data_fields.delete(field.to_sym)
      destroy if (scientific_topic_links.nil? || scientific_topic_links.empty?) && !data
    end

  end

  def reject_data resource, field, value
    data_fields.delete(field.to_sym)
    destroy if (scientific_topic_links.nil? || scientific_topic_links.empty?) && !data
  end

  def data
    return false if data_fields.nil? || data_fields.empty?
    true
  end


end
