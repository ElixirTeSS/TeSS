class RenameEventCurationEmail < ActiveRecord::Migration[7.0]
  def change
    rename_column :content_providers, :event_curation_email, :content_curation_email
  end
end
