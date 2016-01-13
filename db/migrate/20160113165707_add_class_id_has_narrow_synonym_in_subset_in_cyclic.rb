class AddClassIdHasNarrowSynonymInSubsetInCyclic < ActiveRecord::Migration
  def change
  	add_column :scientific_topics, :class_id, :string
  	add_column :scientific_topics, :has_narrow_synonym, :text
  	add_column :scientific_topics, :in_subset, :text
  	add_column :scientific_topics, :in_cyclic, :text
  end
end
