# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# Roles
puts "\nSeeding roles"
Role.create_roles

# Default user
puts "\nSeeding default user"
User.get_default_user

# Scientific Topics
puts "\nSeeding scientific topics"
topic_count = 0
edam_topics = YAML.load(File.open('config/dictionaries/edam.yml'))
edam_topics.each do |edam_topic|
  st = ScientificTopic.find_or_create_by(class_id: edam_topic['class_id'])
  st.assign_attributes(
      preferred_label: edam_topic['preferred_label'],
      synonyms: (edam_topic['synonyms'].split('|') unless edam_topic['synonyms'].nil?),
      definitions: (edam_topic['definitions'].split('|') unless edam_topic['definitions'].nil?),
      obsolete: edam_topic['obsolete'],
      parents: (edam_topic['parents'].split('|') unless edam_topic['parents'].nil?),
      created_in: edam_topic['created_in'],
      documentation: edam_topic['documentation'],
      prefix_iri: edam_topic['prefixIRI'],
      consider: (edam_topic['consider'].split('|') unless edam_topic['consider'].nil?),
      has_alternative_id: (edam_topic['hasAlternativeId'].split('|') unless edam_topic['hasAlternativeId'].nil?),
      has_broad_synonym: (edam_topic['hasBroadSynonym'].split('|') unless edam_topic['hasBroadSynonym'].nil?),
      has_narrow_synonym: (edam_topic['hasNarrowSynonym'].split('|') unless edam_topic['hasNarrowSynonym'].nil?),
      has_dbxref: (edam_topic['hasDbXref'].split('|') unless edam_topic['hasDbXref'].nil?),
      has_definition: edam_topic['hasDefinition'],
      has_exact_synonym: (edam_topic['hasExactSynonym'].split('|') unless edam_topic['hasExactSynonym'].nil?),
      has_related_synonym: (edam_topic['hasRelatedSynonym'].split('|') unless edam_topic['hasRelatedSynonym'].nil?),
      has_subset: (edam_topic['hasSubset'].split('|') unless edam_topic['hasSubset'].nil?),
      in_subset: (edam_topic['inSubset'].split('|') unless edam_topic['inSubset'].nil?),
      replaced_by: (edam_topic['replacedBy'].split('|') unless edam_topic['replacedBy'].nil?),
      saved_by: edam_topic['savedBy'],
      subset_property: (edam_topic['SubsetProperty'].split('|') unless edam_topic['SubsetProperty'].nil?),
      obsolete_since: edam_topic['obsolete_since'],
      in_cyclic: (edam_topic['inCyclic'].split('|') unless edam_topic['inCyclic'].nil?)
  )

  if st.changed?
    st.save!
    topic_count += 1
  end
end

# Nodes
puts "\nSeeding nodes"
path = File.join(Rails.root, 'config', 'data', 'elixir_nodes.json')
hash = JSON.parse(File.read(path))
Node.load_from_hash(hash, verbose: false)

puts "Done"
