class ChangeEventCuratitionEmailToString < ActiveRecord::Migration[7.0]
  def up
    remove_column :content_providers, :send_event_curation_email, :bool
    add_column :content_providers, :event_curation_email, :string
  end

  def down
    add_column :content_providers, :send_event_curation_email, :bool
    remove_column :content_providers, :event_curation_email, :string
  end
end
