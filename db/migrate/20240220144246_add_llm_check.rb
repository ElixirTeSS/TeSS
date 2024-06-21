class AddLlmCheck < ActiveRecord::Migration[7.0]
  def change
    create_table :llm_interactions do |t|
      t.belongs_to :event, foreign_key: true
      t.datetime :created_at
      t.datetime :updated_at
      t.string :scrape_or_process
      t.string :model
      t.string :prompt
      t.string :input
      t.string :output
      t.boolean :needs_processing, default: false
    end
    add_reference :events, :llm_interaction, foreign_key: true
    add_column :events, :open_science, :string, array: true, default: []
  end
end
