class ScientificTopicLink < ActiveRecord::Base

  belongs_to :resource, polymorphic: true

  def scientific_topic
    EDAM::Ontology.instance.lookup(term_uri)
  end

end
