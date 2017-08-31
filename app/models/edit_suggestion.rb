class EditSuggestion < ActiveRecord::Base
  belongs_to :suggestible, polymorphic: true

  include HasScientificTopics

  def accept_suggestion resource, topic
    resource.scientific_topics = resource.scientific_topics.push(topic)
    if resource.save!
      suggestions = drop_topic({uri: topic.uri})
      self.destroy if suggestions.nil? or suggestions.empty?
    end
  end

  def reject_suggestion topic
    suggestions = self.drop_topic({uri: topic.uri})
    destroy if suggestions.empty?
  end

  #Params: :uri => http://edamontology.org/3023
  #        :name => 'RNA-Seq'
  def drop_topic(options = {})
    return nil unless options[:uri].nil?
    topics = scientific_topics
    topic_index = topics.index { |x| x.uri == options[:uri] }
    return nil unless topic_index
    topics.delete_at(topic_index)
    self.scientific_topics = topics
    save!
    scientific_topics
  end

end
