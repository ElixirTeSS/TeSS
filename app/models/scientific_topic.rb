class ScientificTopic < ActiveRecord::Base
  extend FriendlyId
  friendly_id :class_id, use: :slugged


  serialize [:synonyms, :definitions, :parents, :consider,
             :has_alternative_id, :has_broad_synonym, :has_dbxref,
             :has_exact_synonym, :has_related_synonym, :has_subset,
             :replaced_by, :subset_property, :has_narrow_synonym,
             :in_subset, :in_cyclic  ]
end
