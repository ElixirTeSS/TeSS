class ScientificTopicLink < ActiveRecord::Base

  belongs_to :scientific_topic
  belongs_to :resource, polymorphic: true

end
