class AddImageAttachmentToContentProviders < ActiveRecord::Migration[4.2]
  def change
    add_attachment :content_providers, :image
  end
end
