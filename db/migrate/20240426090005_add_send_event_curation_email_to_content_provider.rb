class AddSendEventCurationEmailToContentProvider < ActiveRecord::Migration[7.0]
  def up
    add_column :content_providers, :send_event_curation_email, :bool, default: false
  end

  def down
    remove_column :content_providers, :send_event_curation_email, :bool
  end
end
