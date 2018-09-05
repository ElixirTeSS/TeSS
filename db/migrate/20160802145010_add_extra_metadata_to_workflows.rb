class AddExtraMetadataToWorkflows < ActiveRecord::Migration[4.2]
  def change
    add_column :workflows, :target_audience, :string, array: true, default: []
    add_column :workflows, :scientific_topic, :string, array: true, default: []
    add_column :workflows, :keywords, :string, array: true, default: []
    add_column :workflows, :authors, :string, array: true, default: []
    add_column :workflows, :contributors, :string, array: true, default: []
    add_column :workflows, :licence, :string
    add_column :workflows, :difficulty_level, :string
    add_column :workflows, :doi, :string
    add_column :workflows, :remote_created_date, :date
    add_column :workflows, :remote_updated_date, :date
  end
end
