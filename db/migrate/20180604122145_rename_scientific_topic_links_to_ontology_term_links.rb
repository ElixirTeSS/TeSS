class RenameScientificTopicLinksToOntologyTermLinks < ActiveRecord::Migration[4.2]
  def change
    rename_table :scientific_topic_links, :ontology_term_links
  end
end
