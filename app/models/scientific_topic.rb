class ScientificTopic < ActiveRecord::Base
  extend FriendlyId
  friendly_id :preferred_label, use: :slugged
  has_many :materials
  belongs_to :edit_suggestion


  def self.create_topics
    edam_topics = YAML.load(File.open('config/dictionaries/edam.yml'))
    edam_topics.each do |edam_topic|
      st = ScientificTopic.find_or_create_by(class_id: edam_topic['class_id'])
      st.assign_attributes(
          preferred_label: edam_topic['preferred_label'],
          synonyms: split_field(edam_topic['synonyms']),
          definitions: split_field(edam_topic['definitions']),
          obsolete: edam_topic['obsolete'],
          parents: split_field(edam_topic['parents']),
          created_in: edam_topic['created_in'],
          documentation: edam_topic['documentation'],
          prefix_iri: edam_topic['prefixIRI'],
          consider: split_field(edam_topic['consider']),
          has_alternative_id: split_field(edam_topic['hasAlternativeId']),
          has_broad_synonym: split_field(edam_topic['hasBroadSynonym']),
          has_narrow_synonym: split_field(edam_topic['hasNarrowSynonym']),
          has_dbxref: split_field(edam_topic['hasDbXref']),
          has_definition: edam_topic['hasDefinition'],
          has_exact_synonym: split_field(edam_topic['hasExactSynonym']),
          has_related_synonym: split_field(edam_topic['hasRelatedSynonym']),
          has_subset: split_field(edam_topic['hasSubset']),
          in_subset: split_field(edam_topic['inSubset']),
          replaced_by: split_field(edam_topic['replacedBy']),
          saved_by: edam_topic['savedBy'],
          subset_property: split_field(edam_topic['SubsetProperty']),
          obsolete_since: edam_topic['obsolete_since'],
          in_cyclic: split_field(edam_topic['inCyclic'])
      )

      st.save! if st.changed?
    end
  end

  private

  def self.split_field(field)
    if field.blank?
      []
    else
      field.split('|').reject(&:blank?)
    end
  end
end
