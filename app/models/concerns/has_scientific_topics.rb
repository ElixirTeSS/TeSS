module HasScientificTopics

  extend ActiveSupport::Concern

  included do
    has_many :scientific_topic_links, as: :resource
  end

  def scientific_topic_names= names
    terms = []
    [names].flatten.each do |name|
      unless name.blank? or name == ''
        st = [EDAM::Ontology.instance.lookup_topic_by_name(name)].compact
        st = EDAM::Ontology.instance.find_by(OBO.hasExactSynonym, name) if st.empty?
        st = EDAM::Ontology.instance.find_by(OBO.hasNarrowSynonym, name) if st.empty?
        terms += st
      end
    end
    self.scientific_topics = terms.uniq
  end

  def scientific_topic_names
    scientific_topics.map(&:preferred_label)
  end

  def scientific_topics= terms
    terms.each { |term| scientific_topic_links.build(term_uri: term.uri) if term && term.uri }
  end

  def scientific_topics
    scientific_topic_links.map(&:scientific_topic)
  end

end
