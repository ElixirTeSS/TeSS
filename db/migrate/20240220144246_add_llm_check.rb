class AddLlmCheck < ActiveRecord::Migration[7.0]
  def up
    add_column :events, :llm_processed, :bool, default: false
    add_column :events, :open_science, :string, array: true, default: []
    add_column :events, :curation, :bool, default: true
    add_column :materials, :llm_processed, :bool, default: false
  end

  def down
    remove_column :events, :llm_processed, :bool, default: false
    remove_column :events, :open_science, :string, array: true, default: []
    remove_column :events, :curation, :bool, default: true
    remove_column :materials, :llm_processed, :bool, default: false
  end
end
