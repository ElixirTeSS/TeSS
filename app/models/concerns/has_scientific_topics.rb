module HasScientificTopics

  extend ActiveSupport::Concern

  included do
    has_many :ontology_term_links, as: :resource, dependent: :destroy
  end

  def scientific_topic_names= names
    terms = []
    [names].flatten.each do |name|
      unless name.blank? or name == ''
        st = [EDAM::Ontology.instance.scoped_lookup_by_name(name, OBO_EDAM.topics)].compact
        st = EDAM::Ontology.instance.find_by(OBO.hasExactSynonym, name) if st.empty?
        st = EDAM::Ontology.instance.find_by(OBO.hasNarrowSynonym, name) if st.empty?
        terms += st
      end
    end
    self.scientific_topics = terms.uniq
  end

  def scientific_topic_names
    scientific_topics.map(&:preferred_label).uniq
  end

  def scientific_topics= terms
    self.ontology_term_links = terms.uniq.map { |term| ontology_term_links.build(term_uri: term.uri) if term && term.uri }.compact
  end

  def scientific_topics
    ontology_term_links.map(&:ontology_term).uniq
  end

  def scientific_topic_uris= uris
    self.scientific_topics = uris.map { |uri| EDAM::Ontology.instance.lookup(uri) }
  end

  def scientific_topic_uris
    self.scientific_topics.map(&:uri).uniq
  end
end
