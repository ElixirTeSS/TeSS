class AddImageAttachmentToPackages < ActiveRecord::Migration[4.2]
  def change
    add_attachment :packages, :image
  end
end
