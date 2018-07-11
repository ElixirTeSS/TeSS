class RenameScientificTopicLinksToOntologyTermLinks < ActiveRecord::Migration
  def change
    rename_table :scientific_topic_links, :ontology_term_links
  end
end
