class AddImageAttachmentToPackages < ActiveRecord::Migration
  def change
    add_attachment :packages, :image
  end
end
