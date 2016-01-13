json.array!(@scientific_topics) do |scientific_topic|
  json.extract! scientific_topic, :id, :preferred_label, :synonyms, :definitions, :obsolete, :parents, :created_in, :documentation, :prefix_iri, :consider, :has_alternative_id, :has_broad_synonym, :has_dbxref, :has_definition, :has_exact_synonym, :has_related_synonym, :has_subset, :replaced_by, :saved_by, :subset_property, :obsolete_since
  json.url scientific_topic_url(scientific_topic, format: :json)
end
