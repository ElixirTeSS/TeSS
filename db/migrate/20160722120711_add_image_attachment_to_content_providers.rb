class AddImageAttachmentToContentProviders < ActiveRecord::Migration
  def change
    add_attachment :content_providers, :image
  end
end
