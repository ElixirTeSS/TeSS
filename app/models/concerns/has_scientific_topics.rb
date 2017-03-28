module HasScientificTopics

  extend ActiveSupport::Concern

  included do
    has_many :scientific_topic_links, as: :resource
  end

  def scientific_topic_names= names
    topics = []
    [names].flatten.each do |name|
      unless name.blank? or name == ''
        st = []
        st << EDAM::Ontology.instance.lookup_by_name(name)
        st = EDAM::Ontology.instance.find_by(OBO.hasExactSynonym, name) if st.empty?
        st = EDAM::Ontology.instance.find_by(OBO.hasNarrowSynonym, name) if st.empty?
        topics << st
      end
    end
    self.scientific_topics = topics.flatten.uniq
  end

  def scientific_topic_names
    scientific_topics.map(&:preferred_label)
  end

  def scientific_topics= uris
    uris.each { |uri| scientific_topic_links.build(term_uri: uri) }
  end

  def scientific_topics
    scientific_topic_links.map(&:scientific_topics)
  end

end
