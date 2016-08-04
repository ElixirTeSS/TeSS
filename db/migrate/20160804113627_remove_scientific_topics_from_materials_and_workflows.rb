class RemoveScientificTopicsFromMaterialsAndWorkflows < ActiveRecord::Migration
  def change
    remove_column :materials, :scientific_topics, :string, array: true, default: []
    remove_column :workflows, :scientific_topics, :string, array: true, default: []
  end
end
