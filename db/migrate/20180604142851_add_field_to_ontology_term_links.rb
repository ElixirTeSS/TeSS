class AddFieldToOntologyTermLinks < ActiveRecord::Migration[4.2]
  def change
    add_column :ontology_term_links, :field, :string
    add_index :ontology_term_links, :field
  end
end
