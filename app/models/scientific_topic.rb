class ScientificTopic < ActiveRecord::Base
  serialize [:synonyms, :definitions, :parents, :consider,:has_alternative_id, :has_broad_synonym, :has_dbxref, :has_exact_synonym, :has_related_synonym, :has_subset, :replaced_by, :subset_property]
end
