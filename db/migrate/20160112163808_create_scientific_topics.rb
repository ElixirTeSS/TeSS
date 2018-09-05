class CreateScientificTopics < ActiveRecord::Migration[4.2]
  def change
    create_table :scientific_topics do |t|
      t.string :preferred_label
      t.text :synonyms
      t.text :definitions
      t.boolean :obsolete
      t.text :parents
      t.string :created_in
      t.string :documentation
      t.string :prefix_iri
      t.text :consider
      t.text :has_alternative_id
      t.text :has_broad_synonym
      t.text :has_dbxref
      t.text :has_definition
      t.text :has_exact_synonym
      t.text :has_related_synonym
      t.text :has_subset
      t.text :replaced_by
      t.string :saved_by
      t.text :subset_property
      t.string :obsolete_since

      t.timestamps null: false
    end
  end
end
